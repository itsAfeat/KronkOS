; ------------------------------------------------------------------
; Include file for KronkOS program development (API version 4)
; ------------------------------------------------------------------
; ------------------------------------------------------------------
; IMPORTEN LOCATIONS

    kernel_start            equ 0066h

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

    print               equ 0068h
    cls                 equ 006Bh
    os_file_exists      equ 006Eh
    os_load_file        equ 0071h
    os_create_file      equ 0074h
    os_remove_file      equ 0077h
    os_write_file       equ 007Ah
    string_lowercase    equ 007Dh
    string_uppercase    equ 0080h
    string_truncate     equ 0083h
    string_length       equ 0086h
    move_cursor         equ 0089h
    get_cursor_pos      equ 008Ch
    print_horiz_line    equ 008Fh
    input_dialog        equ 0092h
    list_dialog         equ 0095h
    dialog_box          equ 0098h
    change_cursor       equ 009Bh
    string_clear        equ 009Eh
    os_get_file_list    equ 00A1h
    clear_regs          equ 00A4h
    int_to_string       equ 00A7h

; ------------------------------------------------------------------