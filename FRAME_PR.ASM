.model tiny
.286
.code
org 100h

CMD_PTR equ 81h
VIDEO_PTR equ 0b800h
cnsl_width equ 80d					        ; maximum number of symbol per line (in symbols)
top_ind equ 1					            ; number of symbols from above from the outloop frame (in symbols)
left_ind equ 20					            ; number of symbols on the left of the outloop frame (in symbols)
shadow_colour equ 72d
shadow_cx equ 1d                            ; num of first line where the shadow is painted
cx_start_frame equ 2d                       ; number of line with the upper border of inside frame
cx_finish_frame equ 15d                     ; number of line with the lower border of inside frame
frame_colour equ 109d                       ; code of colour of the frame
fr_high equ 17d                             ; outloop frame's height (in symbols)
fr_len equ 30d                              ; outloop frame's width (in symbols)


Start:
MAIN:
    mov ax, 3509h
    int 21h
    mov Old09Ofs2, bx
    mov bx, es
    mov Old09Seg2, bx
    cli
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, offset PRESS
    mov al, 9h
    mov ah, 25h
    int 21h
    pop ds
    sti


    mov ax, 3508h
    int 21h
    mov Old09Ofs, bx
    mov bx, es
    mov Old09Seg, bx
    cli
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, offset TIME
    mov al, 8h
    mov ah, 25h
    int 21h
    pop ds
    sti


    mov ax, 3100h
    mov dx, offset EOP
    shr dx, 3
    inc dx
    int 21h
;==============================================
; PURPOSE: The handler of pressing. Change 'is_pressed' in case of press combination 'Cntrl + ;'
; ENTRY: Old09Seg2 - segment of the place where was keystroke
;        Old09Ofs2 - index of the place where was keystroke in segment 'Old09Seg'
; ASSUMES: cs
; DESTR: -
; OUTPUT: Is_pressed = 1 or 0
;==============================================
PRESS proc
    push ax bx es dx cx di si ds ss ; TODO not do if wrong key
    in al, 60h
    cmp al, 39d         ; pressed ';'
    jne no

    cmp cs:LastSymbCode, 29d    ; pressed 'Cntrl'
    jne no


    CMP cs:IS_pressed, 0 ; xor with 1
    JE convert_to_one

    convert_to_zero:
        mov cs:IS_pressed, 0
        jmp no

    convert_to_one:
        mov cs:IS_pressed, 1

    NO:
    mov cs:LastSymbCode, al

    pop ss ds si di cx dx es bx ax
        db 0eah ;     far jmp to the place where was keystroke
Old09Ofs2 dw 0
Old09Seg2 dw 0
PRESS endp

;===============================================
; PURPOSE: calling the frame-constructor in case of 'is_pressed = 1'
; ENTRY: Old09Seg - segment of the place where was keystroke
;        Old09Ofs - index of the place where was keystroke in segment 'Old09Seg'
; ASSUMES: cs
; DESTR: -
;===============================================
TIME proc ;bp sp di si ss es ds sp
    push ax bx es dx cx di si ds ss bp        ; saving of start value TODO push beyond je
    cmp CS:is_pressed, 0
    je finish

    call FILL_REG_ARRAY
    call SHOW_FRAME             ; in case of combination 'Cntrl + ;' call frame-constructor

finish:
	pop bp ss ds si di cx dx es bx ax

		 db 0eah ;     far jmp to the place where was keystroke
Old09Ofs dw 0
Old09Seg dw 0
TIME endp
;================================================
; PURPOSE: It is main procedure. Is engaged in frame building
; ENTRY: -
; ASSUMES: ES = 0b8000h; DS = CS
; DESTR: -
;================================================
SHOW_FRAME proc
    PUSH cs
    pop ds
	mov bx, VIDEO_PTR						; The procedure for writing an
	            							; address to a video memory segment
	mov es, bx
	mov cx, 0					            ; cx - the number of the line being processed (counting from above)
    mov bx, start_bx

outer_loop:
    inc cx
	add bx, 2 * cnsl_width		            ; bx - the current index of the cell of the frame in this line
	cmp cx, fr_high
	jae it_end
										    ; Internal loop cycxes through columns
    									    ; incresing argument 'bx'
	call FILL_LINE                          ; checking what symbol should be next
    jmp outer_loop
    it_end:
    call MAKE_SHADOW
    mov shift, 0

    ret
SHOW_FRAME endp
;================================================
; Puts the shadow effect in the right places
; ENTRY: cx - counter of lines
;		 bx - absolute counter of cell
; ASSUMES: ES = 0b800h
; DESTR: bx
;================================================
MAKE_SHADOW proc
    add bx, 2
    push cx
    cld
    mov cx, fr_len
    mov di, bx
    mov al, ' '
    next33: stosw
            mov byte ptr es:[di-1], shadow_colour
        loop next33
    mov byte ptr es:[di+1], shadow_colour
	pop cx
    ret
MAKE_SHADOW endp
;===============================================
; Checking what symbol should be next
; ENTRY: cx - number of current line
; 		 bx - the current index of the cell of the frame in this line
;		 dl - code of current symbol
; ASSUMES: ES = 0b800h
; DESTR: NOTHING
; CHANGE: dl, SI, AX
;===============================================
FILL_LINE	proc
    mov dl, byte ptr frame_colour
	cmp cx, cx_start_frame
	je upper
	jb other

	cmp cx, cx_finish_frame
	je lower
	ja other

    inside:
        lea si, middle_symb
        NOT line_with_reg
        jmp continue
    upper:
        lea si, top_symb
        jmp continue
    lower:
        lea si, lower_symb
        mov line_with_reg, 0
        jmp continue
    other:
        lea si, other_symb

    continue:
        push cx
        mov cx, fr_len
        mov di, bx
        mov dl, byte ptr frame_colour                   ; dl - code of frame's colour
    next2: movsw
        mov byte ptr es:[di-1], dl
        loop next2
    mov byte ptr es:[di+1], dl
	    pop cx
        cmp cx, 1
        jne shadow
        ret
    shadow:
        mov byte ptr es:[di+3], shadow_colour

        cmp line_with_reg, 0
        jNe put_reg

        cmp cx, 2
        je put_heading
        ret

    put_heading:                            ; put the heading in the middle ot top frame
        push cx
        lea si, heading
        mov di, bx
        mov ax, fr_len
        sub ax, heading_len
        add di, ax
        div hui
        mov al, ah
        xor ah, ah
        add di, ax                          ; let's make sure that 'di' are even
        mov cx, heading_len
        put_title_symb: movsb
            inc di
        loop put_title_symb
        pop cx
        ret

    put_reg:
        call PRINT_REGISTER
        RET
FILL_LINE	endp
;========================================================================
; PURPOSE: filling array 'reg_value' with reg's values.
; ENTRY: all registers
; ASSUMES: CS
; DESTR: nothing
; CHANGED: 'reg_value'
;========================================================================
FILL_REG_ARRAY proc
    mov cs:[reg_value], ax
    mov cs:[reg_value+1], bx
    mov cs:[reg_value+2], cx
    mov cs:[reg_value+3], dx
    mov cs:[reg_value+4], si
    mov cs:[reg_value+5], di
    mov cs:[reg_value+6], bp
    mov cs:[reg_value+7], sp
    mov cs:[reg_value+8], ds
    mov cs:[reg_value+9], es
    mov cs:[reg_value+10], ss
    mov cs:[reg_value+11], cs
    RET
FILL_REG_ARRAY endp
;========================================================================
; PURPOSE: put register's name and value into the frame
; ENTRY: BX - the current index of the cell of the frame in this line
; ASSUMES: es = 0b8000h
; DESTR: di, si, 'shift'
;========================================================================

PRINT_REGISTER proc
    cld
    mov di, bx
    add di, 12d                          ; offset from left inside frame border to registers
    lea si, reg_names
    add si, shift
    add si, shift
    push cx
    call PUT_REG_NAME

    add di, 12d                         ; offset from first reg on line to last hex symbol
    call PUT_HEX
    add di, 4d                          ; offset from last hex symb of first value to second reg's name on the line
    INC shift

    call PUT_REG_NAME

    add di, 12d                         ; offset from second reg on line to last hex symbol
    call PUT_HEX
    INC shift

    pop cx
    ret
PRINT_REGISTER endp
;========================================================================
; PURPOSE: putting register's name into VIDEO_PTR:di
; ENTRY: DI - absolute index of last symbol of the converted number in Video Ptr
; ASSUMES: es = 0b8000h
; DESTR: cx, di, si
;========================================================================
PUT_REG_NAME proc
    mov cx, 2
    nnext: movsb
        inc di
    loop nnext
    ret
PUT_REG_NAME endp
;========================================================================
; PURPOSE: Converting decimal value to hexadecimal and put it into VIDEO_PTR:di
; ENTRY: DI - absolute index of last symbol of the converted number in Video Ptr
; ASSUMES: es = 0b8000h
; DESTR: -
;========================================================================
PUT_HEX proc
    push si ax dx di
    lea si, reg_value
    add si, shift
    xor dx, dx
    mov ax, [si]
next_digit:                                      ; the cycle. Searching for a value in a digit
    div hex_divider                              ; DX - mod of dividing, AX - the whole
    call HEX_CONVERTER
    mov es:[di], dl
    xor dx, dx
    sub di, 2
    cmp ax, 0                                    ; if the whole of dividing is '0', we exit from cycle
    ja next_digit

    pop di dx ax si
    ret
PUT_HEX endp

HEXCHAR db '0123456789ABCDEF' ; TODO

;========================================================================
; PURPOSE: Converting decimal to hex
; ENTRY: DX - decimal digit
; ASSUMES: CS
; OUTPUT: dx - code of symbol (digit or 'A', 'B', 'C', 'D', 'E' or 'F')
;========================================================================
HEX_CONVERTER proc

    cmp dx, 9
    jbe digit

    letter:
        add dx, 55d                                             ; shift for the letters
        ret
    digit:
        add dx, 30h                                             ; '0'
        ret
HEX_CONVERTER endp
;========================================================================
start_bx dw (top_ind * cnsl_width + left_ind) * 2	            ; start value of 'bx'

heading_len dw 3                                                ; length of heading
heading db 'REG'                                                ; heading of the frame
hui db 2

reg_names db 'axbxcxdxsidibpspdsessscs'                         ; names of all registers

reg_value dw 13 DUP(?)                                          ; values of registers in the start
shift dw 0                                                      ; shift for 'reg_names' and 'reg_value'
hex_divider dw 16d

top_symb dw 3 DUP(' '), '+', 22 DUP('-'), '+', 3 DUP(' ')       ; line of upper border of inside frame
middle_symb dw 3 DUP(' '), '|', 22 DUP(' '), '|', 3 DUP(' ')    ; lines of border of inside frame between upper and lower
lower_symb dw 3 DUP(' '), '+', 22 DUP('-'), '+', 3 DUP(' ')     ; line of lower border of inside frame
other_symb dw 30 DUP(' ')                                       ; lines of other borders of inside frame

line_with_reg db 0                                              ; '1' if there is put values of registers, '0' else
LastSymbCode db 0                                               ; scan-code of last used keyboard
is_pressed db 0                                                 ; status: is comb 'Cntrl + ;' pressed? YES(1) or NO(0)
;=================================================================
EOP:
END Start
