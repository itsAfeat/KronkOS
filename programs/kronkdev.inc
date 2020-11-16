; ------------------------------------------------------------------
; Include file for KronkOS program development (API version 4)
; ------------------------------------------------------------------
; ------------------------------------------------------------------
; IMPORTEN LOCATIONS

    kernel_start            equ 0x0000

; ------------------------------------------------------------------
; KEYS

    %define KEY_UP          0x48
    %define KEY_DOWN        0x50
    %define KEY_LEFT        0x4B
    %define KEY_RIGHT       0x4D

    %define KEY_ESC         27
    %define KEY_ENTER       13
    %define KEY_SPACE       32

    %define KEY_F1          0x3B00
    %define KEY_F2          0x3C00
    %define KEY_F3          0x3D00
    %define KEY_F4          0x3E00
    %define KEY_F5          0x3F00

    %define KEY_CTRL        17
    %define KEY_SHFT        16

    
; ------------------------------------------------------------------
; SYSTEM CALLS

    ; ***********************
    ; * PROGRAM SUBROUTINES *
    ; ***********************

    print               equ 0002h
    cls                 equ 0005h
    os_file_exists      equ 0008h
    os_load_file        equ 000Bh
    os_create_file      equ 000Eh
    os_remove_file      equ 0011h
    os_write_file       equ 0014h
    string_lowercase    equ 0017h
    string_uppercase    equ 001Ah
    string_truncate     equ 001Dh
    string_length       equ 0020h
    move_cursor         equ 0023h
    get_cursor_pos      equ 0026h
    print_horiz_line    equ 0029h
    input_dialog        equ 002Ch
    list_dialog         equ 002Fh
    dialog_box          equ 0032h
    change_cursor       equ 0035h
    string_clear        equ 0038h

; ------------------------------------------------------------------