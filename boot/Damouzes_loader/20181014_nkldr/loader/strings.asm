%ifndef	__STRINGS_ASM__
%define	__STRINGS_ASM__

;
; Compare two strings
;
strncmp:
	push	ds
	push	si
	push	es
	push	di
	push	cx

	rep	cmpsb

.return:
	pop	cx
	pop	di
	pop	es
	pop	si
	pop	ds
	ret

;
; Determine if a character is alphanumeric
;
; In:		al = character to test
; Return:	al = 0 if not alphanumeric
isalpha:
	cmp	al, ' '
	je	.return
	cmp	al, '0'
	jb	.notalpha
	cmp	al, '9'
	jbe	.return
	cmp	al, 'A'
	jb	.notalpha
	cmp	al, 'Z'
	jbe	.return
	cmp	al, 'a'
	jb	.notalpha
	cmp	al, 'z'
	ja	.notalpha
	jmp	.return

.notalpha:
	sub	al, al

.return:
	ret

%endif ; __STRINGS_ASM__

;
; EOF
;

