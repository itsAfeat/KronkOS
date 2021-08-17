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
    mov [.start_x], dl

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

    .start_x:   dw 0

; ------------------------------------------------------------------
; print_word_hex -- Print a word as hex
; IN: AX = Hex number
;     BH = Page number
;     BL = Attribute

print_word_hex:
    pusha
    xchg al, ah
    call print_byte_hex
    xchg al, ah
    call print_byte_hex
    popa
    ret

; ------------------------------------------------------------------
; print_byte_hex -- Print a byte as hex
; IN: AX = Hex number

print_byte_hex:
    push ax
    push cx
    push bx

    lea bx, [.table]

    mov ah, al
    and al, 0x0f
    mov cl, 4
    shr ah, cl
    xlat
    xchg ah, al
    xlat

    pop bx
    mov ch, ah
    mov ah, 0x0e
    int 0x10
    mov al, ch
    int 0x10

    pop cx
    pop ax
    ret

    .table: db "0123456789ABCDEF", 0