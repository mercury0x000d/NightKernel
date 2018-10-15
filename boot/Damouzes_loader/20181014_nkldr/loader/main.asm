%ifndef	__MAIN_ASM__
%define	__MAIN_ASM__

; clear the direction flag and disable interrupts
main:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

	call	mm_init			; Initialize 'memory manager'

; Setup stack segment
	mov	ax, 512			; Allocate 8kB for stack
	call	allocseg		;
	mov	ss, ax			; And set stack segment
	mov	sp, 8190		; and stack pointer
	xor	bp, bp

; Allocate space for DPB
	mov	ax, DPT_SIZE
	shr	ax, 4
	inc	ax
	call	allocseg
	mov	[cs:dpb_seg], ax

%ifdef	__HAVE_CFG_PARSER__
; Allocate config data structure
	mov	ax, cfg_data_struc.size
	shr	ax, 4
	inc	ax
	call	allocseg
	mov	[cfgdata_seg], ax
	xor	ax, ax
	mov	[cfgdata_off], ax
%endif

	call	vid_init		; Initialize video

;
; Move ourselves out of the way
;
%ifdef __DEBUG__
	mov	ax, cs
	mov	ds, ax
	mov	si, move_msg
	call	puts
%endif

	cld
	cli

	mov	ax, [total_size]
	shr	ax, 4		; Convert to pages
	inc	ax
	call	allocseg	; And call our allocator

%ifdef __DEBUG__
	push	ldr_seg_msg
	push	0
	push	ax
	call	printptr
	add	sp, 6
	push	ss_seg_msg
	push	0
	push	ss
	call	printptr
	add	sp, 6
	push	dpb_seg_msg
	push	0
	push	word [cs:dpb_seg]
	call	printptr
	add	sp, 6
%ifdef	__HAVE_CFG_PARSER__
	push	cfgdata_seg_msg
	push	word [cs:cfgdata_off]
	push	word [cs:cfgdata_seg]
	call	printptr
	add	sp, 6
%endif
%endif

	mov	es, ax		; Setup target
	xor	di, di		; address
	mov	si, start	; Setup source address
	mov	cx, [total_size]; CX contains the # of bytes to move
	rep	movsb		; And start moving!

	push	es
	push	.init
	retf

;
; We should now be somewhere at the top of memory
;
.init:
	sti
	mov	ax, cs		; Make sure DS points
	mov	ds, ax		; to our loader segment

	call	setup_disk_param

;
; Allocate some memory for the boot sector
;
	mov	ax, 32
	call	allocseg
	mov	es, ax
	mov	[cs:bs_seg], ax		; And also keep a handy dandy spare

%ifdef __DEBUG__
	push	bs_seg_msg
	push	0
	push	ax
	call	printptr
	add	sp, 6
%endif

;
; Now copy the bootsector from 0x0000:0x7c000
; to its final resting place
;
	push	ds
	mov	ax, [cs:bs_seg]
	mov	es, ax
	xor	di, di
	xor	si, si
	mov	ds, si
	mov	si, 0x7c00
	mov	cx, 256
	rep	movsw
	pop	ds

;%ifdef	__DEBUG__
;	push	word 512
;	push	word 0
;	push	word [cs:bs_seg]
;	call	dumpmem
;	add	sp, 6
;%endif

;
; Next probe the filesystem type
;
	call	probe_fs_type
	or	al, al
	jnz	.valid_fs

	mov	si, cs
	mov	ds, si
	mov	si, no_valid_fs_msg
	call	puts
	mov	si, reboot_msg
	call	puts
	jmp	.wait_for_key_and_reboot

.valid_fs:
%ifdef	__DEBUG__
	call	print_fs_type

%endif
;
; Next is the root directory
;
	call	get_rootdir_size_in_bytes
	push	ax
	shr	ax, 4			; Convert to pages
	inc	ax
	call	allocseg
	mov	[cs:rd_seg], ax		; And make ourselves a handy dandy copy

	call	get_starting_sector_of_rootdir
	
	mov	cx, ax
	pop	ax
	call	bytes_to_sectors	; And convert to sectors
	mov	[cs:datasector], ax
	add	[cs:datasector], cx
	xchg	cx, ax

%ifdef __DEBUG__
	push	rd_seg_msg
	push	0
	push	word [cs:rd_seg]
	call	printptr
	add	sp, 6
%endif
;
;	Load the root directory
	mov	bx, [cs:rd_seg]
	mov	es, bx
	sub	bx, bx
	sub	dx, dx
	call	load_sects

;%ifdef	__DEBUG__
;	push	word 512
;	push	word 0
;	push	word [cs:rd_seg]
;	call	dumpmem
;	add	sp, 6
;%endif
;
;	Then load the FAT
;
	; Compute size of FAT and store in cx
	call	get_fat_size_in_bytes
	push	ax
	shr	ax, 4  		; Now convert to pages
	inc	ax

	call	allocseg	; And get ourselves a nice new segment

%ifdef __DEBUG__
	push	ft_seg_msg
	push	0
	push	ax
	call	printptr
	add	sp, 6
%endif

	mov	es, ax		;
	mov	[ft_seg], ax	; And make a handy dandy copy of it
	sub	bx, bx
	; Convert the number of bytes to the number of sectors
	pop	ax
	call	bytes_to_sectors
	mov	cx, ax
	; Compute location of FAT and store in ax
	call	get_reserved_sectors
	call	load_sects

%ifdef	__DEBUG__
	push	kernel_seg_msg
	push	word [cs:kernel_off]
	push	word [cs:kernel_seg]
	call	printptr
	add	sp, 6
%endif


%ifdef	__HAVE_CFG_PARSER_
;
;	Try and load the config file first
;	If it is not found, no biggie, we'll
;	just skip it and assume the kernel 
;	is all we need
	mov	si, cs
	mov	ds, si
	mov	si, kcfg_filename
	call	stat
	or	ax, ax
	jz	.load_kernel

	; Note: we only use the low word here
	;       which puts a limit on the file
	;	size for the config file
	mov	ax, [es:bx + d_size]
	shr	ax, 4
	inc	ax
	call	allocseg
	mov	[cs:cfg_seg], ax

	xor	bx, bx
	mov	es, ax
	call	load_from_file

	call	parse_configuration
%endif

.load_kernel:
;
;	Now load the kernel
	mov	si, cs
	mov	ds, si
%ifdef	__DEBUG__
	mov	si, ram_used_msg
	call	puts
	mov	ax, [cs:top_of_mem]
	shl	ax, 6
	sub	ax, [cs:nextseg]
	call	printword
	mov	si, kb_msg
	call	puts
%endif
	mov	si, load_msg
	call	puts
	mov	si, kernel_filename
	mov	bx, [cs:kernel_seg]
	mov	es, bx
	sub	bx, bx

	call	load_from_file

	or	al, al
	jnz	.start_kernel

	mov	ax, cs
	mov	ds, ax

.failed:
	mov	si, failed_msg
	call	puts

.wait_for_key_and_reboot:
	call	waitkey
	int	0x19
	
.start_kernel:
	mov	si, start_msg
	call	puts

%ifdef	__DEBUG__
	call	waitkey
%endif

;
; Kernel is loaded at 0x0000:0x0600 (for now)
;
.fallthrough:
	push	word [kernel_seg]
	push	word [kernel_off]
	retf

%endif ; __MAIN_ASM__

;
; EOF
;
