cls:
    pusha
    
    mov ah, 0x06
    mov dx, 0x184f

    xor al, al
    xor cx, cx

    int 0x10
    
    mov ah, 0x2
    xor dx, dx
    xor bh, bh

    int 0x10
    
    popa
    ret