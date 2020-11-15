; ------------------------------------------------------------------
; print -- Print a string to the screen
; IN: SI = The location of the string

print:
    pusha
    mov ah, 0x0e

.repeat:
    lodsb
    test al, al
    jz .done

    int 0x10
    jmp short .repeat

.done:
    popa
    ret

; ------------------------------------------------------------------
; welcome_print -- Print the welcome message
; IN: SI = The location of the string

welcome_print:
    mov ah, 0x09
    mov cx, 1
    xor bx, bx
    mov bl, mb_color

    .repeat:
        lodsb
        cmp al, 0
        je .done

        cmp al, 0x0a
        je .other_char
        cmp al, 0x0d
        je .other_char

        call get_cursor_pos
        inc dl
        call move_cursor

        int 0x10
        jmp short .repeat

    .other_char:
        mov ah, 0x0e
        int 0x10

        mov ah, 0x09
        jmp .repeat

    .done:
        ret

; ------------------------------------------------------------------
; print_atr -- Print a string with attribute to the screen
; IN: SI = The location of the string
;     BH = Page number
;     BL = Attribute

print_atr:
    pusha
    mov cx, 1
    mov ah, 0x09

.repeat:
    lodsb
    test al, al
    jz .done

    cmp al, 0x0a
    je .special_char

    cmp al, 0x0d
    je .special_char

    int 0x10

    call get_cursor_pos
    inc dl
    call move_cursor

    jmp short .repeat

.special_char:
    mov ah, 0x0e
    int 0x10
    mov ah, 0x09

    jmp short .repeat

.done:
    popa
    ret