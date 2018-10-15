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

%include 'loader/config.inc'

%define	KERNEL_FILENAME	'NYXDOS  SYS'

%define	FFLAG_FATMASK		0x07
%define	FFLAG_FLAGMASK		0xf8
%define	FFLAG_HASFSSIG		0x10
%define	FFLAG_HASV8BPB		0x20
%define	FFLAG_HASV7BPB		0x40
%define	FFLAG_HASBPB		0x80

%define	FSTYPE_UNKNOWN		0x0
%define	FSTYPE_FAT12		0x1
%define	FSTYPE_FAT16		0x2
%define	FSTYPE_FAT32		0x3
%define	FSTYPE_NTFS		0x4

%include "loader/bootsec.inc"	; Definitions for bootsector entries
%include "loader/dirent.inc"	; Definitions for directory entry attributes
%include "loader/cfgdata.inc"	; CFG data structure definition
%include "loader/device.inc"	; Device structure definition

; This is where the FreeDOS bootloader loads this code
org 0x0000
start:
	jmp	main
	nop

%ifdef	__HAVE_MODULE_INFO__
%include 'loader/modinfo.asm'
%endif


;
; All initialized data goes here
;

load_msg:		db	10, 13
			db	'Loading NightDOS kernel... ', 0
%ifdef	__DEBUG__
start_msg:		db	'OK', 10, 13, 'Press any key to start the NightDOS kernel... ', 0
%else
start_msg:		db	'OK', 10, 13, 'Starting NightDOS kernel... ', 0
%endif
no_valid_fs_msg:	db	10, 13, 'No valid filesystem found on disk.', 10, 13, 0

failed_msg:		db	'FAILED!', 10, 13
reboot_msg:		db	'Press any key to reboot... ', 0
nl_msg:			db	10, 13, 0


kernel_filename:
			db	KERNEL_FILENAME, 0

the_fs_type:		db	0
datasector:		dw	0
cluster:		dw	0

top_of_mem:		dw	0
nextseg:		dw	0

kernel_off:		dw	0x0000
kernel_seg:		dw	0x0060


cfg_seg:		dw	0x0000
dpb_seg:		dw	0x0000
bs_seg:			dw	0x0000
rd_seg:			dw	0x0000
ft_seg:			dw	0x0000

saved_ip:		dw	0x0000

align 4

%include 'loader/main.asm'


%include 'loader/mm.asm'
%include 'loader/kbd.asm'
%include 'loader/video.asm'
%include 'loader/strings.asm'
%include 'loader/diskio.asm'
%include 'loader/fatfs.asm'

%ifdef	__HAVE_CFG_PARSER__
%include 'loader/cfgparser.asm'
%endif

%ifdef	__DEBUG__
%include 'loader/debug.asm'
%endif

total_size	dw	$ - start + 2
