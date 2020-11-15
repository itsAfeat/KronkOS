check_com:      ; AX = command
    mov si, in_buffer
    mov di, ax

.check_loop:
    lodsb
    cmp al, [di]
    jne .not_equal
    
    mov al, 0
    cmp [di], al
    je .done

    inc di
    jmp .check_loop

.not_equal:
    stc
    ret

.done:
    clc
    ret