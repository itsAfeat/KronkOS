; ==================================================================
; KronkOS -- The Kronk Operating System kernel
; Copyright (C) 2019-2020 Alexander Wiencken
;
; STRING MANIPULATION ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; string_length -- Return length of a string
; IN: AX = string location
; OUT AX = length (other regs preserved)

string_length:
    pusha
    mov bx, ax
    mov cx, 0

    .more:
        cmp byte [bx], 0
        je .done
        inc bx
        inc cx
        jmp .more

    .done:
        mov word [.tmp_counter], cx
        popa

        mov ax, [.tmp_counter]
        ret

        .tmp_counter dw 0

; ------------------------------------------------------------------
; find_char_in_string -- Find location of character in a string
; IN: SI = string location, AL = character to find
; OUT AX = location in string, or 0 if not present

find_char_in_string:
    pusha
    mov cx, 1

    .more:
        cmp byte [si], al
        je .done
        cmp byte [si], 0
        je .notfound
        
        inc si
        inc cx

        jmp .more
    
    .done:
        mov [.tmp], cx
        popa
        mov ax, [.tmp]

        ret
    
    .notfound:
        popa
        mov ax, 0

        ret

    .tmp dw 0

; ------------------------------------------------------------------
; string_charchange -- Change a character in a string
; IN: SI = string location, AL = char to find, BL = char to replace with

string_charchange:
    pusha
    mov cl, al

    .loop:
        mov byte al, [si]
        cmp al, 0
        je .finish
        cmp al, cl
        jne .nochange

        mov byte [si], bl

    .nochange:
        inc si
        jmp .loop
    
    .finish:
        popa
        ret

; ------------------------------------------------------------------
; string_uppercase -- Convert string to upper case
; IN/OUT: AX = string location

string_uppercase:
    pusha
    mov si, ax

    .more:
        cmp byte [si], 0
        je .done

        cmp byte [si], 'a'
        jb .noatoz
        cmp byte [si], 'z'
        ja .noatoz

        sub byte [si], 0x20

        inc si
        jmp .more

    .noatoz:
        inc si
        jmp .more

    .done:
        popa
        ret

; ------------------------------------------------------------------
; string_lowercase -- Convert string to lower case
; IN/OUT: AX = string location

string_lowercase:
    pusha
    mov si, ax

    .more:
        cmp byte [si], 0
        je .done

        cmp byte [si], 'A'
        jb .noatoz
        cmp byte [si], 'Z'
        ja .noatoz

        add byte [si], 0x20

        inc si
        jmp .more
    
    .noatoz:
        inc si
        jmp .more

    .done:
        popa
        ret
        
; ------------------------------------------------------------------
; string_copy -- Copy one string on to another
; IN: SI = source
; OUT: DI = destination

string_copy:
    pusha

    .more:
        lodsb
        stosb

        test al, al
        jnz .more

    .done:
        popa
        ret

; ------------------------------------------------------------------
; string_truncate -- Chop string down to specified number of characters
; IN: SI = string location, AX = number of characters
; OUT: Modified string

string_truncate:
    pusha

    add si, ax
    mov byte [si], 0

    popa
    ret

; ------------------------------------------------------------------
; string_add
; IN: AX = string one; BX = string two
; OUT AX = product

string_add:
    .add_loop:
        lodsb
        stosb

        cmp al, 0
        jne .add_loop

        ret

; ------------------------------------------------------------------
; string_join -- Join two strings into a third seperate string
; IN/OUT: AX = string one, BX = string two, CX = product destination

string_join:
    pusha
    
    mov si, ax
    mov di, cx

    call string_copy
    call string_length

    add cx, ax

    mov si, bx
    mov di, cx
    call string_copy

    popa
    ret

; ------------------------------------------------------------------
; string_chomp -- Strip away extra spaces from a string
; IN: AX = string location

string_chomp:
    pusha

    mov dx, ax

    mov di, ax
    mov cx, 0

    .keepcounting:
        cmp byte [di], ' '
        jne .counted
        inc cx
        inc di
        jmp .keepcounting

    .counted:
        cmp cx, 0
        je .finished_copy

        mov si, di
        mov di, dx
    
    .keep_copying:
        lodsb
        mov [di], al
        cmp al, 0
        je .finished_copy
        inc di

        jmp .keep_copying

    .finished_copy:
        mov ax, dx

        call string_length
        cmp ax, 0
        je .done

        mov si, dx
        add si, ax
    
    .more:
        dec si
        cmp byte [si], ' '
        jne .done
        mov byte [si], 0
        jmp .more
    
    .done:
        popa
        ret

; ------------------------------------------------------------------
; string_strip -- Remove a character from a string (max 255 chars)
; IN: SI = string location, AL = character to remove
; OUT: SI = modified string

string_strip:
    pusha

    mov di, si
    mov bl, al

    .nextchar:
        lodsb
        stosb
        cmp al, 0
        je .finish
        cmp al, bl
        jne .nextchar

    .skip:
        dec di
        jmp .nextchar

    .finish:
        popa
        ret

; ------------------------------------------------------------------
; string_compare -- Check if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

string_compare:
    pusha

    .more:
        mov al, [si]
        mov bl, [di]

        cmp bl, 0
        je .terminated

        cmp al, bl
        jne .not_same

        inc si
        inc di
        jmp .more
    
    .not_same:
        popa
        clc
        ret
    
    .terminated:
        popa
        stc
        ret

; ------------------------------------------------------------------
; string_to_int -- Convert string to an integer
; IN: SI = string (max 5 chars, up to '65536')
; OUT: AX = number

string_to_int:
    pusha

    mov ax, si
    call string_length

    add si, ax
    dec si

    mov cx, ax

    mov bx, 0
    mov ax, 0

    mov word [.multiplier], 1

    .loop:
        mov ax, 0
        mov byte al, [si]
        sub al, 48

        mul word [.multiplier]
        add bx, ax

        push ax
        mov word ax, [.multiplier]
        mov dx, 10
        mul dx
        mov word [.multiplier], ax
        pop ax

        dec cx
        cmp cx, 0
        je .finish
        dec si
        jmp .loop
    
    .finish:
        mov word [.tmp], bx
        popa
        mov word ax, [.tmp]

        ret

    .multiplier dw 0
    .tmp        dw 0

; ------------------------------------------------------------------
; int_to_string -- Convert unsigned integer to a string
; IN: AX = unsigned int
; OUT: AX = string

int_to_string:
    pusha

    mov cx, 0
    mov bx, 10
    mov di, .t

    .push:
        mov dx, 0
        div bx
        inc cx
        push dx
        test ax, ax
        jnz .push

    .pop:
        pop dx
        add dl, '0'
        mov [di], dl
        inc di
        dec cx
        jnz .pop

        mov byte [di], 0

        popa
        mov ax, .t
        ret

        .t times 7 db 0

; ------------------------------------------------------------------
; sint_to_string -- Convert signed integer to string
; IN: AX = signed int
; OUT: AX = string location

sint_to_string:
    pusha

    mov cx, 0
    mov bx, 10
    mov di, .t

    test ax, ax
    js .neg
    jmp .push

    .neg:
        neg ax
        mov byte [.t], '-'
        inc di
    
    .push:
        mov dx, 0
        div bx
        inc cx
        push dx
        test ax, ax
        jnz .push

    .pop:
        pop dx
        add dl, '0'
        mov [di], dl
        inc di
        dec cx
        jnz .pop

        mov byte [di], 0

        popa
        mov ax, .t
        ret

        .t times 7 db 0
        
; ------------------------------------------------------------------
; lint_to_string -- Convert long integer to string
; IN: DX:AX = long unsigned int, BX = number base, DI = string location
; OUT: DI = location of converted string

lint_to_string:
    pusha

    mov si, di
    mov word [di], 0

    cmp bx, 37
    ja .done

    cmp bx, 0
    je .done

    .conversion_loop:
        mov cx, 0

        xchg ax, cx
        xchg ax, dx
        div bx

        xchg ax, cx
        div bx
        xchg cx, dx
    
    .save_digit:
        cmp cx, 9
        jle .convert_digit

        add cx, 'A'-'9'-1

    .convert_digit:
        add cx, '0'

        push ax
        push bx
        mov ax, si
        call string_length

        mov di, si
        add di, ax
        inc ax
    
    .move_string_up:
        mov bl, [di]
        mov [di+1], bl
        dec di
        dec ax
        jnz .move_string_up

        pop bx
        pop ax
        mov [si], cl
    
    .test_end:
        mov cx, dx
        or cx, ax
        jnz .conversion_loop
    
    .done:
        popa
        ret
        
; ------------------------------------------------------------------
; set_time_fmt -- Set time reporting format (eg '10:25 AM' or '2300 hours')
; IN: AL = format flag, 0 = 12-hr format

set_time_fmt:
	pusha
	cmp al, 0
	je .store
	mov al, 0x0FF
.store:
	mov [fmt_12_24], al
	popa
	ret


; ------------------------------------------------------------------
; get_time_string -- Get current time in a string (eg '10:25')
; OUT: BX = string location

get_time_string:
	pusha

	mov di, bx

	clc
	mov ah, 2
	int 0x1A
	jnc .read

	clc
	mov ah, 2
	int 0x1A

.read:
	mov al, ch
	call bcd_to_int
	mov dx, ax

	mov al,	ch
	shr al, 4
	and ch, 0x0F
	test byte [fmt_12_24], 0x0FF
	jz .twelve_hr

	call .add_digit
	mov al, ch
	call .add_digit
	jmp short .minutes

.twelve_hr:
	cmp dx, 0
	je .midnight

	cmp dx, 10
	jl .twelve_st1

	cmp dx, 12
	jle .twelve_st2

	mov ax, dx
	sub ax, 12
	mov bl, 10
	div bl
	mov ch, ah

	cmp al, 0
	je .twelve_st1

	jmp short .twelve_st2

.midnight:
	mov al, 1
	mov ch, 2

.twelve_st2:
	call .add_digit
.twelve_st1:
	mov al, ch
	call .add_digit

	mov al, ':'
	stosb

.minutes:
	mov al, cl
	shr al, 4
	and cl, 0x0F
	call .add_digit
	mov al, cl
	call .add_digit

	mov al, ' '
	stosb

	mov si, .hours_string
	test byte [fmt_12_24], 0x0FF
	jnz .copy

	mov si, .pm_string
	cmp dx, 12
	jg .copy

	mov si, .am_string

.copy:
    add bl, 1
	lodsb
	stosb
	cmp al, 0
	jne .copy

	popa
	ret

.add_digit:
	add al, '0'
	stosb
	ret


	.hours_string	db 'hours', 0
	.am_string 	db 'AM', 0
	.pm_string 	db 'PM', 0


; ------------------------------------------------------------------
; set_date_fmt -- Set date reporting format (M/D/Y, D/M/Y or Y/M/D - 0, 1, 2)
; IN: AX = format flag, 0-2
; If AX bit 7 = 1 = use name for months
; If AX bit 7 = 0, high byte = separator character

set_date_fmt:
	pusha
	test al, 0x80
	jnz .fmt_clear

	and ax, 0x7F03
	jmp short .fmt_test

.fmt_clear:
	and ax, 0003

.fmt_test:
	cmp al, 3
	jae .leave
	mov [fmt_date], ax

.leave:
	popa
	ret


; ------------------------------------------------------------------
; get_date_string -- Get current date in a string (eg '12/31/2007')
; OUT: BX = string location

get_date_string:
	pusha

	mov di, bx
	mov bx, [fmt_date]
	and bx, 0x7F03

	clc
	mov ah, 4
	int 0x1A
	jnc .read

	clc
	mov ah, 4
	int 0x1A

.read:
	cmp bl, 2
	jne .try_fmt1

	mov ah, ch
	call .add_2digits
	mov ah, cl
	call .add_2digits
	mov al, '/'
	stosb

	mov ah, dh
	call .add_2digits
	mov al, '/'
	stosb

	mov ah, dl
	call .add_2digits
	jmp .done

.try_fmt1:
	cmp bl, 1
	jne .do_fmt0

	mov ah, dl
	call .add_1or2digits

	mov al, bh
	cmp bh, 0
	jne .fmt1_day

	mov al, ' '

.fmt1_day:
	stosb

	mov ah,	dh
	cmp bh, 0
	jne .fmt1_month

	call .add_month
	mov ax, ', '
	stosw
	jmp short .fmt1_century

.fmt1_month:
	call .add_1or2digits
	mov al, bh
	stosb

.fmt1_century:
	mov ah,	ch
	cmp ah, 0
	je .fmt1_year

	call .add_1or2digits

.fmt1_year:
	mov ah, cl
	call .add_2digits

	jmp .done

.do_fmt0:
	mov ah,	dh
	cmp bh, 0
	jne .fmt0_month

	call .add_month
	mov al, ' '
	stosb
	jmp short .fmt0_day

.fmt0_month:
	call .add_1or2digits
	mov al, bh
	stosb

.fmt0_day:
	mov ah, dl
	call .add_1or2digits

	mov al, bh
	cmp bh, 0
	jne .fmt0_day2

	mov al, ','
	stosb
	mov al, ' '

.fmt0_day2:
	stosb

.fmt0_century:
	mov ah,	ch
	cmp ah, 0
	je .fmt0_year

	call .add_1or2digits

.fmt0_year:
	mov ah, cl
	call .add_2digits


.done:
	mov ax, 0
	stosw

	popa
	ret


.add_1or2digits:
	test ah, 0x0F0
	jz .only_one
	call .add_2digits
	jmp short .two_done
.only_one:
	mov al, ah
	and al, 0x0F
	call .add_digit
.two_done:
	ret

.add_2digits:
	mov al, ah
	shr al, 4
	call .add_digit
	mov al, ah
	and al, 0x0F
	call .add_digit
	ret

.add_digit:
	add al, '0'
	stosb
	ret

.add_month:
	push bx
	push cx
	mov al, ah
	call bcd_to_int
	dec al
	mov bl, 4
	mul bl
	mov si, .months
	add si, ax
	mov cx, 4
	rep movsb
	cmp byte [di-1], ' '
	jne .done_month
	dec di
.done_month:
	pop cx
	pop bx
	ret

	.months db 'Jan.Feb.Mar.Apr.May JuneJulyAug.SeptOct.Nov.Dec.'

; ------------------------------------------------------------------
; string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning
; OUT: DI = next token or 0 if none

string_tokenize:
	push si

    .next_char:
	    cmp byte [si], al
	    je .return_token
	    cmp byte [si], 0
	    jz .no_more
	    inc si
	    jmp .next_char

    .return_token:
	    mov byte [si], 0
	    inc si
	    mov di, si
	    pop si
	    ret

    .no_more:
	    mov di, 0
	    pop si
	    ret

; ------------------------------------------------------------------
; string_clear -- Clears a variable
; IN: DI  = variable, AX = length
; OUT: empty variable

string_clear:
    pusha
    mov bx, -1
    
    .loop:
        xor al, al
        stosb
        
        inc bx

        cmp ax, bx
        jne .loop
        popa
        ret

; ==================================================================