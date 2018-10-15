%ifndef	__VIDEO_ASM__
%define	__VIDEO_ASM__

;
; Initialize video card
;
; In:		Nothing
; Return:	Nothing
;
vid_init:
	xor	ah, ah			; Set hardware
	mov	al, 0x03		; text
	int	0x10			; mode

%ifdef	__DEBUG__
	mov	ax, 0x1112
	int	0x10
%endif

	mov	ah, 0x05		; and make
	xor	al, al			; sure we activated
	int	0x10			; page 0
	ret

;
; Print a character to the screen
;
; In:		AL = character to write
; Return:	AL = character written
;
putchar:
	push	ax
	push	bx
	mov	ah, 0x0e
	xor	bh, bh
	int	0x10
	pop	bx
	pop	ax
	ret

;
; Prints an ASCIIZ string to the screen
;
; In:		DS:SI -> ASCIIZ string to write
; Return:	AX = number of characters written
;
puts:	
	push	ds
	push	si
	xor	ax, ax
	push	ax

.loop:
	lodsb
	or	al, al
	je	.done
	call	putchar
	pop	ax
	inc	ax
	push	ax
	jmp	.loop

.done:
	pop	ax
	pop	si
	pop	ds
	ret

%endif ; __VIDEO_ASM__

;
; EOF
;


