%ifndef	__DISKIO_ASM__
%define	__DISKIO_ASM__

;
; This function sets up new floppy disk parameters
; and lets int 0x1e point to it
;
setup_disk_param:
	cli
	cld

	push	ds
	push	es
	push	si
	push	di
	push	ax

	xor	ax, ax
	mov	ds, ax
	lds	si, [0x0078]
	mov	cx, [cs:dpb_seg]
	mov	es, cx
	xor	di, di
	xor	ch, ch
	mov	cl, DPT_SIZE
	rep
	movsb

	sub	cx, cx
	mov	[0x0078], cx
	mov	[0x007a], es

	sti

.reset_boot_drive:
	sub	ah, ah
	int	0x13

	pop	ax
	pop	di
	pop	si
	pop	es
	pop	ds

	ret

;
; Load the CX sectors starting from LBA DX:AX into
; the buffer in [ES:BX]
;
load_sects:
	push	ax
	push	dx
	push	cx

	call	lba2chs
%if 0
	call	print_arguments
%endif
	
	mov	ax, 0x0201
	int	0x13

	pop	cx
	pop	dx
	pop	ax
	jb	load_sects_return
	inc	ax
	jnz	load_sects_next
	inc	dx
	
load_sects_next:
	push	ax
	call	get_bytes_per_sector
	add	bx, ax
	pop	ax

	loop	load_sects

load_sects_return:
	ret


;
; Get the number of bytes per sector
;
; In:		Nothing
; Return:	AX = # of bytes per sector
;
get_bytes_per_sector:
	push	ds

	mov	ax, [cs:bs_seg]
	mov	ds, ax
	mov	ax, [bytes_per_sector]

	pop	ds
	ret
;
; Convert # of bytes to # sectors
;
; In:		AX = number of bytes
; Return:	AX = number of sectors (rounded up)
;
bytes_to_sectors:
	push	ds
	push	dx

	mov	dx, [cs:bs_seg]
	mov	ds, dx
	sub	dx, dx
	div	word [bytes_per_sector]
	or	dx, dx
	jz	.return
	
	inc	ax

.return:
	pop	dx
	pop	ds
	ret

align 4
;disk_param:	times  79 db 0xf6

%endif ; __DISKIO_ASM__

;
; EOF
;

