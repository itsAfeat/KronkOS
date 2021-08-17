; ------------------------------------------------------------------
; show_cursor -- Turns on cursor in text mode
; IN/OUT: Nothing

show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret

; ------------------------------------------------------------------
; change_cursor -- Change the cursors look
; IN: CH = 0x00/0x06

change_cursor:
	pusha

	mov ah, 0x01
	mov cl, 0x07
	int 10h

	popa
	ret

; ------------------------------------------------------------------
; hide_cursor -- Turns off cursor in text mode
; IN/OUT: Nothing

hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret

; ------------------------------------------------------------------
; move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column

move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 0x10

	popa
	ret

; ------------------------------------------------------------------
; get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 0x10

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret

	.tmp dw 0

; ------------------------------------------------------------------
; print_horiz_line -- Draw a horizontal line on the screen
; IN: AX = line type (1 for double (=), otherwise single (-))

print_horiz_line:
	pusha

	mov cx, ax
	mov al, 196

	cmp cx, 1
	jne .ready
	mov al, 205

	.ready:
		mov cx, 0
		mov ah, 0Eh

	.restart:
		int 0x10
		inc cx
		cmp cx, 80
		je .done
		jmp .restart

	.done:
		popa
		ret

; ------------------------------------------------------------------
; input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show, CX = max length
; OUT: AX = string location

input_dialog:
	pusha

	push ax
	push bx

	mov dh, 10
	mov dl, 12

.redbox:
	call move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, 0x1F
	mov al, ' '
	int 0x10
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 11
	call move_cursor

	pop bx
	mov si, bx
	call print

	mov dl, 14
	mov dh, 13
	call move_cursor

	pop ax
	mov bx, cx
	call input_string

	popa
	ret

; ------------------------------------------------------------------
; draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

draw_block:
	pusha

.more:
	call move_cursor		; Move to block starting position

	mov ah, 09h			; Draw colour section
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				; Get ready for next line

	mov ax, 0
	mov al, dh			; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret

; ------------------------------------------------------------------
; dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display)
; IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

dialog_box:
	pusha

	mov [.tmp], dx

	call hide_cursor

	mov dh, 9			; First, draw blue background box
	mov dl, 19

.redbox:				; Loop to draw all lines of box
	call move_cursor

	pusha
	mov ah, 0x09
	mov bh, 0
	mov cx, 42
	mov bl, 0x1F		; White on blue
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	cmp ax, 0			; Skip string params if zero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call move_cursor

	mov si, ax			; First string
	call print

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call move_cursor

	mov si, bx			; Second string
	call print

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call move_cursor

	mov si, cx			; Third string
	call print

.no_third_string:
	mov dx, [.tmp]
	cmp dx, 0
	je .one_button
	cmp dx, 1
	je .two_button


.one_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 35
	mov si, 8
	mov di, 15
	call draw_block

	mov dl, 38			; OK button, centred at bottom of box
	mov dh, 14
	call move_cursor
	mov si, .ok_button_string
	call print

	jmp .one_button_wait


.two_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call move_cursor
	mov si, .ok_button_string
	call print

	mov dl, 44			; Cancel button
	mov dh, 14
	call move_cursor
	mov si, .cancel_button_string
	call print

	mov cx, 0			; Default button = 0
	jmp .two_button_wait



.one_button_wait:
	mov ah, 0x00
	int 0x16

	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	call show_cursor

	popa
	ret


.two_button_wait:
	mov ah, 0x00
	int 0x16
	
	cmp ah, 0x4B			; Left cursor key pressed?
	jne .noleft

	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call draw_block

	mov dl, 30				; OK button
	mov dh, 14
	call move_cursor
	mov si, .ok_button_string
	call print

	mov bl, 0x1F		; White on blue for cancel button
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call draw_block

	mov dl, 44				; Cancel button
	mov dh, 14
	call move_cursor
	mov si, .cancel_button_string
	call print

	mov cx, 0				; And update result we'll return
	jmp .two_button_wait


.noleft:
	cmp ah, 0x4D			; Right cursor key pressed?
	jne .noright


	mov bl, 0x1F		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call draw_block

	mov dl, 30				; OK button
	mov dh, 14
	call move_cursor
	mov si, .ok_button_string
	call print

	mov bl, 11110000b		; White on blue for cancel button
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call draw_block

	mov dl, 44				; Cancel button
	mov dh, 14
	call move_cursor
	mov si, .cancel_button_string
	call print

	mov cx, 1				; And update result we'll return
	jmp .two_button_wait


.noright:
	cmp al, 13				; Wait for enter key (13) to be pressed
	jne .two_button_wait

	call show_cursor

	mov [.tmp], cx			; Keep result after restoring all regs
	popa
	mov ax, [.tmp]

	ret


	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0
	.ok_button_noselect	db '   OK   ', 0
	.cancel_button_noselect	db '   Cancel   ', 0

	.tmp dw 0

; ------------------------------------------------------------------
; input_string --- Get a string from keyboard input
; IN: AX = output address, BX = maximum bytes of output string
; OUT: nothing

input_string:
	pusha

	; If the character count is zero, don't do anything.
	cmp bx, 0
	je .done

	mov di, ax			; DI = Current position in buffer
	
	dec bx				; BX = Maximum characters in string
	mov cx, bx			; CX = Remaining character count

.get_char:
	mov ah, 0x00
	int 0x16

	cmp al, 8
	je .backspace

	cmp al, 13			; The ENTER key ends the prompt
	je .end_string

	; Do not add any characters if the maximum size has been reached.
	jcxz .get_char

	; Only add printable characters (ASCII Values 32-126)
	cmp al, ' '
	jb .get_char

	cmp al, 126
	ja .get_char

	call .add_char

	dec cx
	jmp .get_char

.end_string:
	mov al, 0
	stosb

.done:
	popa
	ret

.backspace:
	; Check if there are any characters to backspace
	cmp cx, bx 
	jae .get_char

	inc cx				; Increase characters remaining

	call .reverse_cursor		; Move back to the previous character
	mov al, ' '			; Print a space on the character
	call .add_char
	call .reverse_cursor		; Now move the cursor back again

	jmp .get_char

.reverse_cursor:
	dec di				; Move the output pointer backwards
	
	call get_cursor_pos
	cmp dl, 0			; Is the cursor at the start of line?
	je .back_line

	dec dl				; If not, just decrease the column
	call move_cursor
	ret

.back_line:
	dec dh				; Otherwise, move the cursor to the end
	mov dl, 79			; of the previous line.
	call move_cursor
	ret


.add_char:
	stosb
	mov ah, 0x0E			; Teletype Function
	mov bh, 0			; Video Page 0
	mov bl, 0x0f
	push bp				; Some BIOS's may mess up BP
	int 0x10
	pop bp
	ret

; ------------------------------------------------------------------
; switch_mode -- Switch between VIDEO and CLI mode
; IN: AX = mode (0 for CLI and 1 for video)
;	  BH = color scheme (only background for video)
; OUT: Switches mode

switch_mode:
	pusha
	xor bl, bl

	test ax, ax
	je .switch_cli

	cmp ax, 1
	je .switch_vid

.switch_cli:
	; Switch to text mode
	mov ax, cliRes
	int 0x10

	; Change the cursor
	xor cx, cx
	call change_cursor

	; Clear the screen and change color scheme
	call cls

	jmp .done

.switch_vid:
	; Switch to video mode
	mov ax, vidRes
	int 0x10

	; Clear the screen and change the background color
	call cls

	jmp .done

.done:
	popa
	ret

; ------------------------------------------------------------------
; setup_bottom_string -- Draw a string in the bottom of the setup screen
; IN: SI = String location

setup_bottom_string:
	push si
    mov dh, 23
    xor dl, dl
    call move_cursor

    mov ax, 1
    call print_horiz_line
	
	pop si
    call print

    xor dx, dx
    call move_cursor

	ret

; ------------------------------------------------------------------
; setup_input -- Get keyboard input for the setup
; IN: AX = string location
; OUT: AX = string location

setup_input:
	pusha
	mov di, ax
	push ax

	; Position the mouse
	mov ah, 0x03
	mov bh, 0
	int 0x10

	mov ah, 0x02
	mov dl, 27
	inc dh
	int 0x10

	; And draw the top/sides
	mov si, .top_bar
	call print

	mov ah, 0x02
	mov dl, 27
	inc dh
	int 0x10
	
	mov [.mouse_pos], dh
	mov si, .sidl_bar
	call print
	
	mov ah, 0x02
	mov dl, 27
	inc dh
	int 0x10

	mov si, .bot_bar
	call print

	mov ah, 0x02
	mov dl, 27
	mov dh, [.mouse_pos]
	int 0x10

	xor bl, bl

	; Clear the string location
.clear_loop:
	mov al, 0
	stosb
	inc bl

	cmp bl, 20
	jne .clear_loop

	mov ah, 0x03
	mov bh, 0
	int 0x10

	mov ah, 0x02
	mov dl, 29
	int 0x10

	pop ax
	mov di, ax
	xor bl, bl

.input_loop:
	mov ah, 0x03
	mov bh, 0
	int 0x10

	mov [.mouse_pos], dl

	mov ah, 0x02
	mov dl, 48
	int 0x10

	mov si, .sidr_bar
	call print

	mov ah, 0x02
	mov dl, [.mouse_pos]
	int 0x10

	mov ah, 0x00
	int 0x16

	cmp al, 0x0d
	je .input_done

	cmp al, 0x08
	jne .not_back

	; Pressed backspace
	mov ah, 0x03
	mov bh, 0
	int 0x10

	cmp dl, 29
	je .input_loop

	dec dl
	dec bl

	mov ah, 0x02
	int 0x10

	mov ah, 0x0e
	mov al, 0
	int 0x10
	
	mov ah, 0x02
	int 0x10

	dec di
	mov al, 0
	stosb
	dec di

	jmp .input_loop

.not_back:
	cmp bl, 19
	je .input_loop
	inc bl

	stosb

	mov ah, 0x0e
	int 0x10

	jmp .input_loop 

.input_done:
	popa
	ret

.top_bar:	db 0xda
			times 21 db 0xc4
			db 0xbf, 0x0a, 0
.sidl_bar:	db 0xb3, 0x20, 0
.sidr_bar:	db 0x20, 0xb3, 0x0a, 0
.bot_bar:	db 0xc0
			times 21 db 0xc4
			db 0xd9, 0x0a, 0x0d, 0

.mouse_pos:	db 29

; ------------------------------------------------------------------
; setup_choose -- Draw text and use the cursors to choose between them
; IN: AX, BX, CX = options
;	  DH = not focused color
;	  DL = focused color
; OUT: AX = options choosen (starting at 0)

setup_choose:
	call hide_cursor
	pusha
	push dx

	mov dl, [.start_x]
	mov dh, [.start_y]
	call move_cursor
	pop dx
	
	mov si, ax
	mov di, .option1
	call string_copy
	
	mov si, bx
	mov di, .option2
	call string_copy

	mov si, cx
	mov di, .option3
	call string_copy

	xor cx, cx
	jmp .choose_loop

	jmp .done

.choose_loop:
	call .print_options
	call .check_arrows
	call .clear_bottom

	cmp ax, 3
	jne .choose_loop
	jmp .done

.check_arrows:
	pusha
    mov si, setup_string
    call setup_bottom_string
	popa

	xor ax, ax
	int 0x16

	cmp ah, 0x48	; UP
	je .up
	cmp ah, 0x50	; DOWN
	je .down

	cmp al, 0x0D	; ENTER
	je .enter

	ret				; Failsafe return

	.up:
		test cx, cx
		jz .at_top

		dec cx
		ret
	
		.at_top:
			mov cx, 2
			ret
	
	.down:
		cmp cx, 2
		je .at_bottom

		inc cx
		ret

		.at_bottom:
			xor cx, cx
			ret

	.enter:
		mov ax, 3
		ret

.print_options:
	cmp cx, 0
	je .mark_1

	cmp cx, 1
	je .mark_2

	cmp cx, 2
	je .mark_3

	.mark_1:
		mov si, .option1
		call .print_marked

		mov si, .option2
		call .print_normal

		mov si, .option3
		call .print_normal

		jmp .mark_done
	
	.mark_2:
		mov si, .option1
		call .print_normal

		mov si, .option2
		call .print_marked

		mov si, .option3
		call .print_normal

		jmp .mark_done
	
	.mark_3:
		mov si, .option1
		call .print_normal

		mov si, .option2
		call .print_normal

		mov si, .option3
		call .print_marked

	.mark_done:
		ret

.print_normal:
	call .print_space
	call print
	call .new_line

	ret

.print_marked:
	push bx

	call .print_space
	xor bx, bx
	mov bl, dl
	call print_atr
	call .new_line

	pop bx
	ret

.print_space:
	push bx

	xor bx, bx
	mov bx, .screen_mid
	
	mov ax, si
	call string_length
	sar ax, 1

	sub bx, ax

	.space_loop:
		mov ah, 0x0e
		mov al, ' '
		int 0x10

		dec bx
		test bx, bx
		jnz .space_loop

	pop bx
	ret

.new_line:
	push ax

	mov ax, 0x0E0A
	int 0x10
	mov ax, 0x0E0D
	int 0x10

	pop ax
	ret

.clear_bottom:
	pusha

	mov dh, [.start_y]
	mov dl, [.start_x]
	call move_cursor

	mov ax, 0x070A
	mov bh, 0x1F
	xor cx, cx
	mov dx, 0x184f
	int 0x10
	
	mov ax, 0x060A
	mov bh, 0x1F
	xor cx, cx
	mov dx, 0x184f
	int 0x10

	popa
	ret

.done:
	call .clear_bottom
	mov [.option_picked], cx

	popa
	call show_cursor

	movzx ax, [.option_picked]
	ret

.screen_mid		equ 40
.start_x:		db 0
.start_y:		db 18

.option1:		times 40 db 0
.option2:		times 40 db 0
.option3:		times 40 db 0

.option_picked:	db 0

; ------------------------------------------------------------------
; draw_setup_box -- Draw a text box for the setup
; IN: SI = location of the string
; OUT: prints a box that's meant for the setup

draw_setup_box:
	pusha
	xor bl, bl

	xor dx, dx
	call move_cursor

	push si
	mov si, .setbox_top
	call print

	mov si, .setbox_nwl
	call print

	pop si

.print_loop:
	lodsb
	test al, al
	je .done

	cmp al, 0x0a
	je .new_line

	cmp bl, 48
	je .new_line

	mov ah, 0x0e
	int 0x10
	
	inc bl

	jmp .print_loop

.new_line:
	call .finish_line

	push si
	mov si, .setbox_nwl
	call print
	pop si

	jmp .print_loop

.finish_line:
	mov bh, border_length-2
	sub bh, bl

.finish_loop:
	cmp bh, 0
	jbe .loop_done

	mov ah, 0x0e
	mov al, " "
	int 0x10
	dec bh

	jmp .finish_loop

.loop_done:
	push si
	mov si, .setbox_fnl
	call print
	pop si
	xor bx, bx

	mov ax, 0x0e0a
	int 0x10

	mov ax, 0x0e0d
	int 0x10
	
	ret

.done:
	call .finish_line

	mov si, .setbox_bot
	call print

	popa
	ret
	

.setbox_top:	db 0x0a
        		times edge_width db " "
                db 0xDA
                times border_length db 0xC4
                db 0xBF, 0x0a, 0x0d, 0

.setbox_bot:	times edge_width db " "
                db 0xC0
                times border_length db 0xC4
                db 0xD9, 0x0a, 0x0d, 0

.setbox_nwl:	times edge_width db " "
				db 0xB3, " ", 0

.setbox_fnl:	db " ", 0xB3, 0

; ------------------------------------------------------------------
; draw_box -- Draw a box
; IN: AL = color
;	  BX = end x position
;	  CX = end y position
;	  DH = start x position
;	  DL = start y position
; OUT: Draws box

draw_box:
	pusha

	mov [.startx], dh
	mov [.starty], dl
	mov [.endx], bx
	mov [.endy], cx

	mov cx, [.startx]
	mov dx, [.starty]
	mov ah, 0x0C

	.x_loop:
		cmp cx, [.endx]
		je .y_loop

		int 0x10

		inc cx
		jmp .x_loop

	.y_loop:
		int 0x10

		cmp dx, [.endy]
		je .done

		mov cx, [.startx]
		inc dx
		jmp .x_loop
	
	.done:
		popa
		ret

	.tmp:    dw 0
	.startx: dw 0
	.starty: dw 0
	.endx:   dw 0
	.endy:	 dw 0

; ------------------------------------------------------------------
; list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

list_dialog:
	pusha

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl

	mov bl, 0x9F		; White on light blue
	mov dl, 15			; Start X position
	mov dh, 2			; Start Y position
	mov si, 50			; Width
	mov di, 23			; Finish Y position
	call draw_block		; Draw option selector window

	mov dl, 16			; Show first line of help text...
	mov dh, 3
	call move_cursor

	pop si				; Get back first string
	call print

	inc dh				; ...and the second
	call move_cursor

	pop si
	call print


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 20			; Set up starting position for selector
	mov dh, 7

	call move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 16
	mov dh, 6
	mov si, 48
	mov di, 22
	call draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	mov ah, 0x00
	int 0x16

	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	jmp .more_select		; If not, wait for another key


.go_up:
	cmp dh, 7			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select



.option_selected:
	call show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call show_cursor
	popa
	stc				; Set carry for Esc
	ret



.draw_list:
	pusha

	mov dl, 18			; Get into position for option list text
	mov dh, 7
	call move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	lodsb				; Get next character in file name, increment pointer

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 18			; Go back to starting X position
	inc dh				; But jump down a line
	call move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 14			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 17
	call move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 46
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 17
	call move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 46
	mov bl, 11110000b		; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0