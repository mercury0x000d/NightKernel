%ifndef	__FATFS_ASM__
%define	__FATFS_ASM__

;
; Determine the FAT type
;
; In:		Nothing.
; Return:	AL = FAT filesystem type (12, 16, 32) + flags.
;		AH = 0
;
; Flags:
;
; 76543210 -- bit nr
; |||||\++--- FAT filesystem type (0 = Non-FAT, 1 = FAT12, 
; |||||       2 = FAT16, 3 = FAT32, 4 = NTFS)
; ||||\------ ignored (must be zero)
; |||\------- if set, a filesystem signature was found in the BPB
; ||\-------- if set, an NTFS BPBP was found
; |\--------- if set, a DOS 7.0 BPB was found
; \---------- if set, a BPB was found
; 
;
probe_fs_type:
	push	ds
	push	si
	push	cx
	push	dx
	mov	ax, [cs:bs_seg]
	mov	ds, ax
	xor	ax, ax
	mov	byte [cs:the_fs_type], 0
	mov	ah, [v7_bpb_signature]
	cmp	ah, 0x28
	je	.is_v7_bpb
	cmp	ah, 0x29
	je	.is_v7_bpb
	jmp	.is_not_v7_bpb

.is_v7_bpb:
	mov	si, v7_bpb_fstype
	mov	cx, 8
.is_v7_bpb_loop:
	lodsb
	call	isalpha
	or	al, al
	jz	.is_not_v7_bpb
	loop	.is_v7_bpb_loop

	or	byte [cs:the_fs_type], FFLAG_HASV7BPB|FFLAG_HASBPB|FFLAG_HASFSSIG
	mov	si, v7_bpb_fstype
	call	probe_fs_signature
	and	dl, FFLAG_FATMASK
	add	byte [cs:the_fs_type], dl
	jmp	.return

.is_not_v7_bpb:
	mov	ah, [v4_bpb_signature]
	cmp	ah, 0x28
	je	.is_v4_bpb
	cmp	ah, 0x29
	je	.is_v4_bpb
	jmp	.is_not_v4_bpb

.is_v4_bpb:
	mov	si, v4_bpb_fstype
	mov	cx, 8

.is_v4_bpb_loop:
	lodsb
	call	isalpha
	or	al, al
	jz	.is_not_v4_bpb
	loop	.is_v4_bpb_loop

	or	byte [cs:the_fs_type], FFLAG_HASBPB|FFLAG_HASFSSIG
	mov	si, v4_bpb_fstype
	call	probe_fs_signature
	and	dl, FFLAG_FATMASK
	add	byte [cs:the_fs_type], dl
	jmp	.return
	

.is_not_v4_bpb:
	cmp	byte [v4_bpb_signature], 0x80
	jne	.return
	

.is_v8_bpb:
	or	byte [cs:the_fs_type], FFLAG_HASV8BPB|FFLAG_HASBPB
	add	byte [cs:the_fs_type], FSTYPE_NTFS
	jmp	.return	

.return:
	mov	al, [cs:the_fs_type]
	pop	dx
	pop	cx
	pop	si
	pop	ds
	ret

;
; Probe the FS signature
;
; In:		DS:SI -> fs signature
; Return:	DL = filesystem type (0 = unknown, 1 = FAT12, 
;		2 = FAT16, 3 = FAT32)
;
probe_fs_signature:
	push	es
	push	di
	push	cx
	push	bx

	xor	dx, dx
	push	cs
	pop	es
	mov	bx, fs_types

;	push	es_bx_msg
;	push	bx
;	push	es
;	call	printptr
;	add	sp, 6

;	push	ds_si_msg
;	push	si
;	push	ds
;	call	printptr
;	add	sp, 6


.loop:
	mov	di, [es:bx]
;	push	es_di_msg
;	push	di
;	push	es
;	call	printptr
;	add	sp, 6
	or	di, di
	jz	.end_of_loop
	mov	cx, 8
	call	strncmp
	je	.return
	add	bx, 2
	inc	dx
	jmp	.loop

	jmp	.return

.end_of_loop:

.return:
	pop	bx
	pop	cx
	pop	di
	pop	es
	ret


;
; Convert cluster number to LBA
;
; In:		AX	Cluster #
; Return:	AX	LBA #
;
cluster2lba:
	push	ds
	push	cx
	mov	cx, [cs:bs_seg]
	mov	ds, cx
	sub	ax, 0x0002
	sub	cx, cx
	mov	cl, [sectors_per_cluster]
	mul	cx
	add	ax, [cs:datasector]
	pop	cx
	pop	ds
	ret
;
; Convert (32-bit) LBA to C/H/S
;
; In:		DX:AX		32-bit LBA
;
; Return:	CH		Low eight bits of cylinder number
;		CL		(bits 0-5) Sector number
;				(bits 6-7) High 2 bits of cylinder number
;		DH		Head number
;		DL		Logical drive number
;
; Preserves:	Nothing
;
lba2chs:
	push	ds
	push	ax
	push	word [cs:bs_seg]
	pop	ds
	
	xchg	cx, ax
	xchg	dx, ax
	xor	dx, dx
	div	word [sectors_per_track]
	xchg	cx, ax
	div	word [sectors_per_track]
	inc	dx
	xchg	dx, cx
	div	word [head_count]
	mov	dh, dl
	mov	dl, [logical_drive_num]
	mov	ch, al
	ror	ah, 2
	or	cl, ah
	
lba2chs_return:
	pop	ax
	pop	ds
	ret

;
; Get the number of reserved sectors
;
; In:		Nothing
; Return:	AX = the number of reserved sectors
;
get_reserved_sectors:
	push	ds
	mov	ax, [cs:bs_seg]
	mov	ds, ax
	mov	ax, [reserved_sectors]

.return:
	pop	ds
	ret


;
; Get the size of the root directory in bytes
;
; In:		Nothing
; Return:	AX = size of root directory in bytes
;
get_rootdir_size_in_bytes:
	push	ds
	push	cx
	push	dx

	mov	ax, [cs:bs_seg]
	mov	ds, ax
	sub	cx, cx
	sub 	dx, dx
	mov	ax, 0x0020
	mov	cx, ax
	mov	ax, [root_directory_entries]
	mul	cx
	
.return:
	pop	dx
	pop	cx
	pop	ds
	ret

;
; Get the starting LBA of the root directory
;
; In:		Nothing
; Return:	AX = starting LBA of root directory
;
get_starting_sector_of_rootdir:
	push	ds
	mov	ax, [cs:bs_seg]
	mov	ds, ax
	sub	ax, ax
	mov	al, [fat_copies]
	mul	word [sectors_per_fat]
	add	ax, word [reserved_sectors]

.return:
	pop	ds
	ret 
;
; Get the total size of the FAT in bytes
;
; In:		Nothing
; Return:	AX = # of bytes in FAT
;
get_fat_size_in_bytes:
	push	ds
	mov	ax, [cs:bs_seg]
	mov	ds, ax
	sub	ax, ax
	mov	al, [fat_copies]
	mul	word [sectors_per_fat]
	mul	word [bytes_per_sector]

.return:
	pop	ds
	ret
;
; Load the kernel from file
;
; In:		DS:SI -> filename
; 		ES:BX -> memory block to load to
load_from_file:
	push	ds
	push	si
	push	es
	push	bx

	call	findfile
	or	ax, ax
	jz	.error

;	AX should now contain the starting cluster of the file
	call	load_fat_file
	jmp	.return
	mov	ax, 1

.error:
	or	ax, ax

.return:
	pop	bx
	pop	es
	pop	si
	pop	ds
	ret	

;
; Load file using FAT tables
;
; In:		AX:	Starting cluster of file.
; 		ES:BX -> address to load file to.
; Return:	AX:	0 on error, non-zero if ok.
;
load_fat_file:
	push	bp
	mov	bp, sp	
	sub	sp, 2		; Need 2 bytes local storage
	push	es
	push	cx
	push	ds
	push	bx
	mov	[bp - 2], ax
	mov	ax, [cs:ft_seg]
	mov	ds, ax

.load:
	mov	ax, [bp - 2]
	call	cluster2lba
	mov	cx, 1		; FIXME? Put real sector count (1) here.
	pop	bx
	call	load_sects	; No need to advance BX, load_sects will do that for us
	push	bx

	; Compute next cluster
	mov	ax, [bp - 2]
	call	get_fat_word
	test	ax, 0x0001
	jnz	.load_odd_cluster

.load_even_cluster:
	and	dx, 0xfff		; Take low twelve bits
	jmp	.load_next

.load_odd_cluster:
	shr	dx, 4			; Take high twelve bits

.load_next:
	mov	[bp - 2], dx
	cmp	dx, 0xff0		; Test for EOF
	jb	.load

.load_done:
	mov	ax, 1

.return:
	pop	bx
	pop	ds
	pop	cx
	pop	es
	add	sp, 2
	pop	bp
	ret

;
; Load the FAT word for cluster <ax> into <dx>
;
; In:		AX = cluster #
; Return:	DX = FAT word
;
get_fat_word:
	push	ds
	push	bx

	mov	bx, ax
	mov	dx, ax
	shr	dx, 1
	add	bx, dx
	mov	dx, [cs:ft_seg]
	mov	ds, dx
	mov	dx, [bx]
	
.return:
	pop	bx
	pop	ds
	ret

;
; Get directory entry for file
;
; In		DS:SI ->	filename
; Return	ES:BX ->	directory entry for file
;		AX:		0 on error
;
stat:
	push	ds
	push	si

	mov	ax, [cs:rd_seg]
	mov	es, ax
	call	get_number_of_root_directory_entries

	mov	cx, ax
	sub	di, di
	mov	bx, si
	xor	ax, ax

.loop:
	push	cx
	push	di
	mov	si, bx
	mov	cx, 0x000b
	rep	cmpsb
	pop	di
	pop	cx
	je	.found
	add	di, 0x0020
	loop	.loop
	xor	ax, ax
	sub	bx, bx
	jmp	.return

.found:
	mov	bx, di
	inc	ax

.return:
	pop	si
	pop	ds
	ret
	
;
; Find file
;
; In		DS:SI ->	filename
; Return	AX:		Starting cluster of file (zero if not found)
;
findfile:
	push	cx
	push	es
	push	di
	push	bx

	call	stat
	or	ax, ax
	jz	.return

	mov	ax, [es:bx + d_startcluster]

.return:
	pop	bx
	pop	di
	pop	es
	pop	cx
	ret

;
; Get the number of root directory entries
;
get_number_of_root_directory_entries:
	push	ds
	mov	ax, [cs:bs_seg]
	mov	ds, ax
	mov	ax, [root_directory_entries]

.return:
	pop	ds
	ret

align 4
unknown_str:		db	'(unknown)', 0
fat12_str:		db	'FAT12   ', 0
fat16_str:		db	'FAT16   ', 0
fat32_str:		db	'FAT32   ', 0

align 4
fs_types:		dw	unknown_str
			dw	fat12_str
			dw	fat16_str
			dw	fat32_str
			dw	0

%endif ; __FATFS_ASM__

;
; EOF
;

