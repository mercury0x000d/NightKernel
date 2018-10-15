%ifndef	__MM_ASM__
%define __MM_ASM__

;
; Initialize 'memory manager'
;
; In:		Nothing
; Return:	AX = last available memory segment
;
mm_init:
	int	0x12			; Obtain memory size in kB
	mov	[top_of_mem], ax	; Save to variable
	shl	ax, 6			; And convert to pages
	mov	[nextseg], ax		; Store it for later use
	ret

;
; Allocate <ax> pages of memory
;
; In:		AX = number of 16 byte pages to allocate
; Return:	AX = new segment
;
allocseg:
	sub	[cs:nextseg], ax
	mov	ax, [cs:nextseg]
	ret

%endif ; __MM_ASM__

;
; EOF
;

