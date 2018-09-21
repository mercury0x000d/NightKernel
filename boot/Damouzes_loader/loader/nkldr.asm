;
; NKLDR - Night Kernel LoaDeR
; (c) 2018- by Desert Mouse, donated to the Night Kernel project
;
; This program can be used as a drop-in replacement for FreeDOS's
; KERNEL.SYS. Its purpose is to load the actual Night kernel. 
;
; Note: this code is meant as a proof-of-concept.
;
; This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.
;
; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.
;
; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.
;
;
; A short explanation on the program:
;
; 1.) This program, assembled as kernel.sys, will first move itself to somewhere
;     at the top of conventional memory and continue execution there. 
; 2.) It wil then more memory for the boot sector (which it will move from its
;     loading spot at 0x0000:0x7c00 to the allocated segment).
; 3.) After setting the BPB, it will allocate memory for the root directory
;     and the FAT and load each of these into its own segment. 
; 4.) Now that all the prerequisites for handling files on a FAT12
;     filesystem are there, it will try to load the kernel (called
;     'nyxdos.sys') to 0x0060:0x0000 and transfer control to it.
;
; Known limitations:
; * This program is largely agnostic as to where in memory it is loaded,
;   especially since it will move itself to the top of conventional memory
;   anyway. That said, loading it into the top of conventional memory
;   beforehand may result in undefined behaviour.
; * This program only handles FAT12 filesystems. This should be enough for
;   testing purposes on a floppy.
;
[map all nkldr.map] 
bits 16

;%define	__DEBUG__

%include "loader/bootsec.inc"	; Definitions for bootsector entries
%include "loader/dirent.inc"	; Definitions for directory entry attributes

; This is where the FreeDOS bootloader loads this code
org 0x0000
start:
	jmp 	main	; Just because we can

signature:
	db	'NKLDR$$$'

; clear the direction flag and disable interrupts
main:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

; Setup stack segment
	int	0x12		; Obtain memory size in kB
	sub	ax, 8		; Reserve 8kB for our stack
	shl	ax, 6		; And convert to pages
	mov	[nextseg], ax	; Store it for later use
	mov	ss, ax		; And set stack segment
	mov	sp, 8190	; and stack pointer
	xor	bp, bp


	xor	ah, ah		; Set hardware
	mov	al, 0x03	; text
	int	0x10		; mode

%ifdef	__DEBUG__
	mov	ax, 0x1112
	int	0x10
%endif

	mov	ah, 0x05	; and make
	xor	al, al		; sure we activated
	int	0x10		; page 0

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
%endif

	mov	es, ax		; Setup target
	xor	di, di		; address
	mov	si, start	; Setup source address
	mov	cx, [total_size]; CX contains the # of bytes to move
	rep	movsb		; And start moving!

	push	es
	push	init
	retf

;
; We should now be somewhere at the top of memory
;
init:
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

%if 0
	push	word 512
	push	word 0
	push	word [cs:bs_seg]
	call	dumpmem
	add	sp, 6
%endif

;
; Next is the root directory
;
	call	get_rootdir_size_in_bytes
;	call	printword_spc
	push	ax
	shr	ax, 4			; Convert to pages
	call	allocseg
	mov	[cs:rd_seg], ax		; And make ourselves a handy dandy copy


	call	get_starting_sector_of_rootdir
;	call	printword_spc
	
	mov	cx, ax
	pop	ax
	call	bytes_to_sectors	; And convert to sectors
;	call	printword_spc
	mov	[cs:datasector], ax
	add	[cs:datasector], cx
;	call	printword_spc
	xchg	cx, ax
;	call	printword_spc

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

%ifdef	__DEBUG__
	push	word 512
	push	word 0
	push	word [cs:rd_seg]
	call	dumpmem
	add	sp, 6
%endif
;
;	Then load the FAT
;
	; Compute size of FAT and store in cx
	call	get_fat_size_in_bytes
	push	ax
	shr	ax, 4  		; Now convert to pages

;	call	printword_spc
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
;	call	printword_spc
	mov	cx, ax
	; Compute location of FAT and store in ax
	call	get_reserved_sectors
;	call	printword_spc
	call	load_sects

%if 0
	push	word 512
	push	word 0
	push	word [cs:ft_seg]
	call	dumpmem
	add	sp, 6
%endif

%if 0
	push	kernel_seg_msg
	push	bx
	push	word [cs:kernel_seg]
	call	printptr
	add	sp, 6
%endif

	mov	si, load_msg
	call	puts

;
;	Now load the kernel
	mov	si, cs
	mov	ds, si
	mov	si, kernel_filename
	mov	bx, [cs:kernel_seg]
	mov	es, bx
	sub	bx, bx

	call	load_kernel_from_file

	or	al, al
	jnz	start_kernel

	mov	ax, cs
	mov	ds, ax

	mov	si, failed_msg
	call	puts

	call	waitkey
	int	0x19
	
start_kernel:
	mov	si, start_msg
	call	puts
%ifdef	__DEBUG__
	call	waitkey
%endif

;
; Kernel is loaded at 0x0000:0x0600 (for now)
;
	push	word [kernel_seg]
	push	word [kernel_off]
	retf

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
;	call	printword_spc
	mov	ds, ax
	sub	cx, cx
	sub 	dx, dx
	mov	ax, 0x0020
;	call	printword_spc
	mov	cx, ax
	mov	ax, [root_directory_entries]
;	call	printword_spc
	mul	cx
;	call	printword_spc
	
.return:
	pop	dx
	pop	cx
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
;	call	printword_spc
	mul	word [sectors_per_fat]
;	call	printword_spc
	mul	word [bytes_per_sector]
;	call	printword_spc

.return:
	pop	ds
	ret
;
; Load the kernel from file
;
; In:		DS:SI -> filename
; 		ES:BX -> memory block to load to
load_kernel_from_file:
	push	ds
	push	si
	push	es
	push	bx

%if 0
	push	0
	push	bx
	push	es
	call	printptr
	add	sp, 6
%endif

	call	findfile
	or	ax, ax
	jz	.error

%if 0
	push	0
	push	bx
	push	es
	call	printptr
	add	sp, 6
%endif
	
;	AX should now contain the starting cluster of the file
;	call	printword_spc
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
;	call	printword_spc
	mov	ax, [cs:ft_seg]
	mov	ds, ax

.load:
	mov	ax, [bp - 2]
;	call	printword_spc
	call	cluster2lba
;	call	printword_spc
	mov	cx, 1		; FIXME? Put real sector count (1) here.
	pop	bx
	call	load_sects	; No need to advance BX, load_sects will do that for us
	push	bx
%if 0
	push	0
	push	bx
	push	es
	call	printptr
	add	sp, 6
%endif
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
; Find file
;
; In		DS:SI -> filename
; Return	AX: Starting cluster of file (zero if not found)
findfile:
	push	cx
	push	es
	push	di
	push	bx

	mov	ax, [cs:rd_seg]
	mov	es, ax
	call	get_number_of_root_directory_entries

	mov	cx, ax
	sub	di, di
	mov	bx, si
	xor	ax, ax
;	push	di

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
	jmp	.return

.found:
	mov	ax, [es:di + d_startcluster]
%if 0
	push	0
	push	di
	push	es
	call	printptr
	add	sp, 6
	push	ax
	mov	al, ' '
	call	putchar
	pop	ax
%endif

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
	mov	cx, cs
	mov	es, cx
	mov	di, disk_param
	xor	ch, ch
	mov	cl, 0x0b
	rep
	movsb

	mov	cx, disk_param
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

%if 0
;
; Load the kernel into ES:BX
;
load_kernel:
;	xor	al, al
;	ret


;
; First load a single sector of the root directory
;
find_image:
;	Calculate size of root directory in sectors and store in CX

;
; Now search the root directory for the binary image
;
	mov	cx, [root_directory_entries]
	sub	di, di

find_image_loop:
	push	cx
	mov	cx, 0x000b
	mov	si, kernel_filename
	rep	cmpsb
	pop	di
	je	load_fat
	pop	cx
	add	di, 0x0020
	loop	find_image_loop
	jmp	failure

load_fat:
	; Save starting cluster of boot image
	mov	dx, [di + 0x001a]
	mov	[cluster], dx
	; Load FAT into memory (overwrites previously loaded
	; root directory)
	mov	bx, [cs:kernel_off]
	
	call	load_sects
	; Read image file into memory (0060:0000)
;	mov	bx, [kernel_off]
;	push	bx
load_image:
	mov	ax, [cluster]
	pop	bx
	call	cluster2lba
	sub	cx, cx
	call	load_sects
	push	bx
	; Compute next cluster
	mov	ax, [cluster]
	mov	cx, ax
	mov	dx, ax
	shr	dx, 1
	add	cx, dx
	mov	bx, 0x7e00	; Segment 0 address of I/O buffer containing FAT copy
	add	bx, cx
	mov	dx, [bx]
	test	ax, 0x0001
	jnz	load_odd_cluster

load_even_cluster:
	and	dx, 0xfff	; Take low twelve bits
	jmp	load_image_next

load_odd_cluster:
	shr	dx, 4		; Take high twelve bits

load_image_next:
	mov	[cluster], dx
	cmp	dx, 0xff0	; Test for EOF
	jb	load_image

load_image_done:
	mov	al, 1
	jmp	do_return

failure:
	or	al, al

do_return:
	ret
%endif
;
;

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

%ifdef	__DEBUG__

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

%endif

;
; All initialized data goes here
;
%ifdef __DEBUG__
move_msg:		db	10, 13
			db	'Moving ourselves out of the way... ', 10, 13, 0
%endif

load_msg:		db	10, 13
			db	'Loading NightDOS kernel... ', 0
%ifdef	__DEBUG__
start_msg:		db	'OK', 10, 13, 'Press any key to start the NightDOS kernel... ', 0
%else
start_msg:		db	'OK', 10, 13, 'Starting NightDOS kernel... ', 0
%endif
failed_msg:		db	'FAILED!', 10, 13
			db	'Press any key to reboot... ', 0

nl_msg:			db	10, 13, 0

%ifdef __DEBUG__
debug_msg:		db	10, 13, ' DEBUG: CS:IP = ', 0
ptr_msg:		db	10, 13, ' PTR -> ', 0
bs_seg_msg		db	10, 13, ' * Boot sector -> ', 0
ldr_seg_msg		db	10, 13, ' * Loader -> ', 0
ss_seg_msg		db	10, 13, ' * Stack -> ', 0
rd_seg_msg		db	10, 13, ' * Root directory -> ', 0
ft_seg_msg		db	10, 13, ' * FAT -> ', 0
kernel_seg_msg		db	10, 13, ' * Kernel -> ', 0
%endif

kernel_filename:
			db	'NYXDOS  SYS', 0

datasector:		dw	0
cluster:		dw	0

nextseg:		dw	0

kernel_off:		dw	0x0000
kernel_seg:		dw	0x0060
bs_seg			dw	0x0000
rd_seg			dw	0x0000
ft_seg			dw	0x0000

saved_ip		dw	0x0000

disk_param:	times  60 db 0x00
%if 0
;
; Make this file 2048 bytes
padding:	times 2046 - ($ - $$)	db 0x00
%endif

total_size	dw	$ - start + 2
