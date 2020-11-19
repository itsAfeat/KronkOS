; get_api_version -- Return current version of KronkOS API
; OUT: AL = API version number

get_api_version:
	mov al, KRONKOS_API
	ret

; ------------------------------------------------------------------
; clear_regs -- Clear all the registers

clear_regs:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di
	
	ret

; ------------------------------------------------------------------
; fatal_error -- Display error message and halt execution
; IN: AX = error message string location

fatal_error:
	mov bx, ax			; Store string location for now

	mov dh, 0
	mov dl, 0
	call move_cursor

	pusha
	mov ah, 0x09		; Draw red bar at top
	mov bh, 0
	mov cx, 240
	mov bl, 01001111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call move_cursor

	mov si, .msg_inform		; Inform of fatal error
	call print

	mov si, bx			; Program-supplied error message
	call print

	jmp $				; Halt execution

	
	.msg_inform		db 'FATAL OPERATING SYSTEM ERROR!', 0x0d, 0x0a, 0

; ------------------------------------------------------------------
; bios_wait -- Wait
; IN: CX:DX time

bios_wait:
	mov ax, 0x8600
    int 0x15
    ret