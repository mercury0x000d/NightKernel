; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; paging.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; includes
%include "include/errors.inc"





bits 32





section .text
PageDirNew:
	; Creates a complete new empty page directory
	;
	;  input:
	;	Flags
	;
	;  output:
	;	ESI - Address of new page directory

	push ebp
	mov ebp, esp

	; define input parameters
	%define inputFlags							dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define pageDirPtr							dword [ebp - 4]


	; get a chunk of RAM that's 4KiB in size, enough for 1024 32-bit page directory entries (PDEs), and aligned on a 4096-byte boundary
	push dword 4096
	push dword 4096
	push dword 0x01
	call MemAllocateAligned

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov pageDirPtr, eax

	; load input flags and mask off address area
	mov ebx, inputFlags
	and ebx, 0x00000FFF

	; Force default flags off. This selects the following:
	; bit 8 - This bit is ignored anyway
	; bit 7 - 4 KiB pages (all we support for now)
	; bit 6 - This bit must be zero
	; bit 0 - not present (since this is a new empty page dir and all)
	and ebx, 11111111111111111111111100011110b

	; Force default flags on. This selects the following:
	; bit 4 - Cache disabled (for now, to simplify debugging)
	; bit 3 - Write-through caching
	or ebx, 00000000000000000000000000011000b


	; start a loop which sets the flags set on each PDE
	mov ecx, 1024
	.PDELoop:
		; calculate the address of this PDE
		dec ecx
		lea esi, [eax + ecx * 4]
		inc ecx

		mov dword [esi], ebx
	loop .PDELoop

	; set the address and error code
	mov esi, pageDirPtr
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
PageTableNew:
	; Creates a complete new empty page table
	;
	;  input:
	;	Flags
	;
	;  output:
	;	ESI - Address of new page table

	push ebp
	mov ebp, esp

	; define input parameters
	%define entryFlags							dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define pageTablePtr						dword [ebp - 4]


	; get a chunk of RAM that's 4KiB in size, enough for 1024 32-bit page table entries (PTEs), and aligned on a 4096-byte boundary
	push dword 4096
	push dword 4096
	push dword 0x01
	call MemAllocateAligned

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov pageTablePtr, eax

	; load flags and mask off address area
	mov ebx, entryFlags
	and ebx, 0x00000FFF

	; Force default flags off. This selects the following:
	; bit 8 - Global flag off; the TLB will not update its cache upon reset of CR3
	; bit 7 - This bit must be zero (no PAT here!)
	; bit 0 - not present (since this is a new empty page dir and all)
	and ebx, 11111111111111111111111100011110b

	; Force default flags on. This selects the following:
	; bit 4 - Cache disabled (for now, to simplify debugging)
	; bit 3 - Write-through caching
	or ebx, 00000000000000000000000000011000b


	; start a loop which sets the flags set on each PTE
	mov ecx, 1024
	.PTELoop:
		; calculate the address of this PTE
		dec ecx
		lea esi, [eax + ecx * 4]
		inc ecx

		mov dword [esi], ebx
	loop .PTELoop

	; set the address and error code
	mov esi, pageTablePtr
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4











; experimental paging setup
cli

push 0
call PageDirCreate
mov dword [PDAddr], eax

push 0
call PageTableCreate
mov dword [PTAddr], eax


; insert page table into page directory while leaving the flags alone which we just set earlier
; set up the first 4 MiB
mov ecx, dword [PDAddr]
mov eax, [ecx]
and eax, 3
mov ebx, dword [PTAddr]
or ebx, eax
or ebx, 1			; set the "present" bit
mov eax, dword [PDAddr]
mov [eax], ebx

; and now point the second 4 MiB to the first
mov ecx, dword [PDAddr]
mov eax, [ecx]
and eax, 3
mov ebx, dword [PTAddr]
or ebx, eax
or ebx, 1			; set the "present" bit
mov eax, dword [PDAddr]
add eax, 4			; this advances to the second entry
mov [eax], ebx

; turn it all on!
mov eax, dword [PDAddr]
mov cr3, eax

; enable paging
mov eax, cr0
or eax, 0x80000000
mov cr0, eax

; that's it! paging is active

; Here we will do a test write at 0x400000 - the 4 MiB mark.
; If all went well, a dump of RAM in the VirtualBox debugger should show the same data
; at both address 0x000000 and 0x400000, even though we only wrote it at 0x400000.
; How is this possible? THE MAGIC OF PAGING IS AMONG US!
mov eax, 0x00400000
mov dword [eax], 0xCAFEBEEF

; hang here so we can survey our success!
jmp $

PDAddr									dd 0x00000000
PTAddr									dd 0x00000000



PageDirCreate:
	push ebp
	mov ebp, esp

	sub esp, 4
	%define PDAddress							dword [ebp - 4]

	; get a chunk of RAM that's 4KiB in size (enough for 1024 32-bit page directory entries) and aligned on a 4096-byte boundary
	push dword 4096
	push dword 4096
	push dword 0x01
	call MemAllocateAligned
	mov PDAddress, eax

	; set default settings on every page directory entry
	mov ecx, 1024
	.setLoop:
		; calculate the address of this page directory entry
		mov eax, 4
		mov ebx, ecx
		dec ebx
		mov edx, 0
		mul ebx
		add eax, PDAddress

		; set this page directory entry to 0x00000002 - specifying it is to be read/write
		mov dword [eax], 0x00000002
	loop .setLoop

	mov eax, PDAddress

	mov esp, ebp
	pop ebp
ret

PageTableCreate:
	push ebp
	mov ebp, esp

	sub esp, 4
	%define PTAddress							dword [ebp - 4]

	; get a chunk of RAM that's 4KiB in size (enough for 1024 32-bit page table entries) and aligned on a 4096-byte boundary
	push dword 4096
	push dword 4096
	push dword 0x01
	call MemAllocateAligned
	mov PTAddress, eax

	mov ecx, 1024
	.setLoop:
		; calculate the address of this page table entry
		mov eax, 4
		mov ebx, ecx
		dec ebx
		mov edx, 0
		mul ebx
		add eax, PTAddress
		push eax

		mov eax, 0x1000
		mul ebx
		or eax, 3

		pop ebx
		mov dword [ebx], eax
	loop .setLoop

	mov eax, PTAddress

	mov esp, ebp
	pop ebp
ret


; The maximum memory a real mode program can address is 1114096 bytes; 0x0000:0000 to 0xFFFF:FFFF.
; This is 272 pages of 4096 bytes each.
