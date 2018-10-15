%ifndef	__KBD_ASM__
%define	__KBD_ASM__

;
; Wait for keyboard input
;
; In:		Nothing
; Return:	AH = BIOS scan code
;		AL = ASCII char
waitkey:
	xor	ax, ax
	int	0x16
	ret

%endif ; __KBD_ASM__

;
; EOF
;

