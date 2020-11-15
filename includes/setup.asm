; ==================================================================
; The Kronk Operating System setup file
; Copyright (C) 2019 - 2020 Alexander Wiencken
;
; This is loaded from the drive by KERNEL.BIN, at first boot
; ==================================================================
setup_init:

    ; Color variables
    basic_colors    equ 0x1F
    marked_colors   equ 0x1E

    ; Setup text box variables
    edge_width      equ 14
    border_length   equ 50
    
    ; Disable color blinking
    mov ax, 0x1003
    mov bx, 0x0000
    int 0x10

    jmp setup_start

; ******************************************************************
; Start the setup
setup_start:
    pusha
    mov bh, basic_colors
    call cls

    mov si, setup_string
    call setup_bottom_string

    mov si, usr_set
    call draw_setup_box

    mov ax, usr_save
    call setup_input

    mov bh, basic_colors
    call cls

    mov si, vid_set
    call draw_setup_box

    mov ax, vid_opt1
    mov bx, vid_opt2
    mov cx, vid_opt3
    mov dx, 0x1fe1
    call setup_choose

    cmp ax, 2
    jne .setup_done

    ; User has choosen "cancel" and KronkOS will therefore shutdown
    xor ax, ax
    int 0x13

    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

.setup_done:
    mov [vidMode], ax

    mov si, usr_save
    mov di, usrNam
    call string_copy

    popa
    ret

; ******************************************************************

; ------------------------------------------------------------------
; VARIABLES
    vidmode_save:   db "videomode,", 0
    cli_save:       db "0", 0x0a, 0x0d, 0
    vid_save:       db "1", 0x0a, 0x0d, 0
    usrname_save:   db "username,", 0
    usr_save:       times 20 db 0

    usr_set:    db "Please enter your username, and press enter...", 0

    vid_set:    db "Please choose a standard view mode...", 0x0a, 0x0a
                db "VIDEO MODE is for the more casual user, that", 0x0a, "just want to be able to use KronkOS with ease by using a nice graphical interface.", 0x0a, 0x0a
                db "CLI MODE is for the more advanced user, where", 0x0a, "instead of pressing buttons, you use commands to", 0x0a, "execute the various actions you desire.", 0x0a, 0x0a
                db "Use the arrow keys and 'ENTER' to select between the different options", 0

    vid_opt1:   db "CLI MODE", 0
    vid_opt2:   db "VIDEO MODE", 0
    vid_opt3:   db "Cancel (Will shutdown KronkOS)", 0

    vid_chosen: dw 0

    setup_string: db " KronkOS ", KRONKOS_VER, " setup", 0