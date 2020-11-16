BITS 16
ORG 32768

jmp start

    %include "kronkdev.inc"

start:
    mov bh, 0x0F
    call cls

    mov si, .tmp
    call print

    mov ah, 0x00
    int 0x16
    ret

.tmp:   db "Satans lort", 0