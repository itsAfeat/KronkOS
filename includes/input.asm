get_input:
    pusha
    mov dl, 0
    mov si, in_buffer

    ; Clear the input buffer for use
    .clear_loop:
        mov byte [si], 0

        inc si
        inc dl

        cmp dl, 30
        jne .clear_loop

    mov si, in_buffer
    xor bl, bl ; Used for checking the length of the buffer

; The actual loop
.input_loop:
    mov ah, 0x00
    int 0x16

    ; Check if the user pressed enter
    cmp al, 0x0d
    je .input_done

    ; Check if the user pressed backspace
    cmp al, 0x08
    jne .not_back

    ; ******************************
    ; The user pressed backspace!

    ; Get current cursor position
    mov ah, 0x03
    mov bh, 0
    int 0x10

    cmp dl, 3 ; 3 = backspace limit
    je .input_loop

    dec dl
    dec bl

    ; Move one back
    mov ah, 0x02
    int 0x10

    mov ah, 0x0e
    mov al, 0
    int 0x10

    mov ah, 0x02
    int 0x10

    ; Remove the last character from the input buffer
    dec si
    mov al, 0
    mov [si], al

    jmp .input_loop
    
    ; ******************************

    ; Show the pressed character and save it to the input buffer
    .not_back:
        cmp bl, 40
        je .input_loop
        inc bl

        mov [si], al
        inc si

        mov ah, 0x0e
        cmp al, 'a'
        jb .noatoz
        cmp al, 'z'
        ja .noatoz
        
        and al, 0xdf
        .noatoz:
        int 0x10

        jmp .input_loop

    ; Return the cursor to the start and return
    .input_done:
        mov ax, in_buffer
        call string_lowercase

        mov ah, 0x0e
        mov al, 0x0d
        int 0x10

        popa
        ret