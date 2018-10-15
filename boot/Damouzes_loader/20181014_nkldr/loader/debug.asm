%ifndef	__DEBUG_ASM__
%define	__DEBUG_ASM__

print_fs_type:
	push	ax
	mov	si, cs
	mov	ds, si
	mov	si, fs_type_msg
	call	puts
	pop	ax
	push	ax
	and	ax, FFLAG_FATMASK
	shl	ax, 1
	mov	si, fs_types
	add	si, ax
	mov	si, [si]
	call	puts
	mov	si, probe_byte_msg
	call	puts
	pop	ax
	call	printbyte
.return:
	ret

printnibble:
	push	ax

	and	al, 0x0f
	add	al, 0x90
	daa
	adc	al, 0x40
	daa

	call	putchar
	
	pop	ax
	ret

printbyte:
	push	ax
	push	cx
	mov	cx, 2

.loop1:
	rol	al, 4
	call	printnibble
	loop	.loop1

.exit:
	pop	cx
	pop	ax
	ret

printword:
	push	ax
	push	cx
	mov	cx, 4

.loop1:
	rol	ax, 4
	call	printnibble
	loop	.loop1

.exit:
	pop	cx
	pop	ax
	ret

ip2ax:
	pop	ax
	push	ax
	ret

printword_spc:
	push	ax
	call	printword
	mov	al, ' '
	call	putchar
	pop	ax
	ret

printbyte_spc:
	push	ax
	call	printbyte
	mov	al, ' '
	call	putchar
	pop	ax
	ret

printword_spc_indirect:
	push	bp
	mov	bp, sp
	push	ds
	push	bx
	push	ax

	mov	bx, [bp + 4]
	mov	ds, bx
	mov	bx, [bp + 6]
	mov	ax, [bx]
	call	printword_spc

.return:
	pop	ax
	pop	bx
	pop	ds
	pop	bp
	ret

printbyte_spc_indirect:
	push	bp
	mov	bp, sp
	push	ds
	push	bx
	push	ax

	mov	bx, [bp + 4]
	mov	ds, bx
	mov	bx, [bp + 6]
	mov	al, [bx]
	call	printbyte_spc

.return:
	pop	ax
	pop	bx
	pop	ds
	pop	bp
	ret

printptr:
	push	bp
	mov	bp, sp

	push	ds
	push	si
	push	ax

	mov	ax, cs
	mov	ds, ax
	mov	si, [bp + 8]
	or	si, si
	jnz	.print
	mov	si, ptr_msg

.print:
	call	puts

	mov	ax, [bp + 4]
	call	printword

	mov	al, ':'
	call	putchar

	mov	ax, [bp + 6]
	call	printword

;	mov	si, nl_msg
;	call	puts

	pop	ax
	pop	si
	pop	ds
	pop	bp
	ret
	
debug:
	pop	word [cs:saved_ip]
	push	word [cs:saved_ip]
	push	ds
	push	si
	push	ax

	mov	ax, cs
	mov	ds, ax
	push	debug_msg
	push	word [cs:saved_ip]
	push	cs
	call	printptr
	add	sp, 6
	mov	si, nl_msg
	call	puts
	
	pop	ax
	pop	si
	pop	ds
	ret

;
; Dumps a memory area to the screen
;
; In:		- Starting address 
;		- Number of bytes to dump
;
dumpmem:
	push	bp
	mov	bp, sp

	push	ds
	push	si
	push	cx

	mov	si, [bp + 4]
	mov	ds, si
	mov	si, [bp + 6]
	mov	cx, [bp + 8]

.loop_outer:
	push	cx
	push	nl_msg
	push	si
	push	ds
	call	printptr
	add	sp, 6

	mov	al, ' '
	call	putchar
	mov	al, '|'
	call	putchar
	mov	al, ' '
	call	putchar
	
	mov	cx, 16
	push	si

.loop_hexbytes:
	lodsb
	call	printbyte_spc
	loop	.loop_hexbytes

	mov	cx, 16
	pop	si

.loop_charprint:
	lodsb
	cmp	al, 32
	ja	.loop_charprint_test2
	
	mov	al, '.'
	jmp	.loop_charprint_doprint

.loop_charprint_test2:
	cmp	al, 126
	jb	.loop_charprint_doprint

	mov	al, '.'	

.loop_charprint_doprint:
	call	putchar
	loop	.loop_charprint

;	call	waitkey
	pop	cx
	sub	cx, 15
	loop	.loop_outer
	
.return:
	pop	cx
	pop	si
	pop	ds
	pop	bp
	ret

;
; Print the arguments that came out of lba2chs
;
print_arguments:
	push	cx
	push	dx

	mov	al, ' '
	call	putchar

	mov	al, cl
	call	printbyte_spc
	mov	al, ch
	call	printbyte_spc
	mov	al, dl
	call	printbyte_spc
	mov	al, dh
	call	printbyte_spc
	push	sectors_per_track
	push	word [cs:bs_seg]
	call	printword_spc_indirect
	add	sp, 4
	push	head_count
	push	word [cs:bs_seg]
	call	printword_spc_indirect
	add	sp, 4
	push	0
	push	bx
	push	es
	call	printptr
	add	sp, 6

.return:
	pop	dx
	pop	cx
	ret

%ifdef __DEBUG__
move_msg:		db	10, 13
			db	'Moving ourselves out of the way... ', 10, 13, 0
debug_msg:		db	10, 13, ' DEBUG: CS:IP = ', 0
ds_si_msg:		db	10, 13, ' DS:SI -> ', 0
es_di_msg:		db	10, 13, ' ES:DI -> ', 0
es_bx_msg:		db	10, 13, ' ES:BX -> ', 0
ptr_msg:		db	10, 13, ' PTR -> ', 0
bs_seg_msg		db	10, 13, ' * Boot sector -> ', 0
fs_type_msg:		db	10, 13, '   = Filesystem type is ', 0
ldr_seg_msg:		db	10, 13, ' * Loader -> ', 0
ss_seg_msg:		db	10, 13, ' * Stack -> ', 0
dpb_seg_msg:		db	10, 13, ' * DPB -> ', 0
%ifdef	__HAVE_CFG_PARSER__
cfgdata_seg_msg:	db	10, 13, ' * Config data -> ', 0
%endif
rd_seg_msg:		db	10, 13, ' * Root directory -> ', 0
ft_seg_msg:		db	10, 13, ' * FAT -> ', 0
kernel_seg_msg:		db	10, 13, ' * Kernel -> ', 0
probe_byte_msg:		db	', probe byte = 0x', 0
ram_used_msg:		db	10, 13, 'Total amount of RAM used: ', 0
kb_msg:			db	' 16-byte pages', 0

%endif

%endif ; __DEBUG_ASM__

;
; EOF
;

