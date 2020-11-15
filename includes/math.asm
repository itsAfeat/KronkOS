; ==================================================================
; KronkOS -- The Kronk Operating System kernel
; Copyright (C) 2019 - 2020 Alexander Wiencken
;
; MATH ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; seed_random -- Seed the random number generator based on clock

seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0
	out 0x70, al
	in al, 0x71

	mov word [random_seed], bx

	pop ax
	pop bx
	ret

	random_seed dw 0

; ------------------------------------------------------------------
; get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

get_random:
	push dx
	push bx
	push ax

	sub bx, ax
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax
	ret

	.generate_random:
		push dx
		push bx

		mov ax, [random_seed]
		mov dx, 0x7383
		mul dx
		mov [random_seed], ax

		pop bx
		pop dx
		
		ret

; ------------------------------------------------------------------
; bcd_to_int -- Converts binary coded decimal number to an integer
; IN: AL = BCD number
; OUT: AX = integer value

bcd_to_int:
	pusha

	mov bl, al

	and ax, 0x0F
	mov cx, ax

	shr bl, 4
	mov al, 10
	mul bl

	add ax, cx
	mov [.tmp], ax

	popa
	mov ax, [.tmp]
	ret

	.tmp	dw 0
	
; ------------------------------------------------------------------
; long_int_negate -- Multiply value in DX:AX by -1
; IN: DX:AX = long integer
; OUT: DX:AX = -(initial DX:AX)

long_int_negate:
	neg ax
	adc dx, 0
	neg dx
	ret

; ------------------------------------------------------------------
; hex_to_int -- Convert a hexadecimal to decimal
; IN: AX = number to be converted, BX = base

hex_to_int:
	ret

; ==================================================================