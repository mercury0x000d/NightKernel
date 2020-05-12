; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
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
%include "include/pagingDefines.inc"

%include "include/errors.inc"
%include "include/memory.inc"





bits 32





section .text
PagingInit:
	; Initializes the CPU for paging
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp


	; map the first 64KiB as supervisor only...
	


	; and all the rest (upto 1 MiB) as user
	



	.Exit:
	mov esp, ebp
	pop ebp
ret





section .text
PagingMap:
	; Maps the specified number of physical pages to virtual pages
	;
	;  input:
	;	Address of Page Directory
	;	Starting address of virtual memory range
	;	Starting address of physical memory range
	;	Number of 4 KiB chunks to be mapped
	;	Flags to be assigned to mapped pages
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define pageDirPtr							dword [ebp + 8]
	%define virtualPtr							dword [ebp + 12]
	%define physicalPtr							dword [ebp + 16]
	%define pageCount							dword [ebp + 20]
	%define inputFlags							dword [ebp + 24]

	; allocate local variables
	sub esp, 4
	%define flagMask							dword [ebp - 4]


	; mask the flags, and set the present bit
	mov eax, inputFlags
	and eax, 0x00000FFF
	or eax, 00000000000000000000000000000001b
	mov flagMask, eax

	; set up a loop to step through the number of pages requested
	mov eax, virtualPtr
	mov ebx, physicalPtr
	mov ecx, pageCount
	mov esi, pageDirPtr
	.PageLoop:

		; calculate PDE number
		mov edx, eax
		shr edx, 22

		; calculate the address of this PDE
		lea edi, [esi + edx * 4]

		; now update the PDE with the new address + flags
		mov edx, ebx
		and edx, 0xFFC00000
		or edx, flagMask
		mov [edi], edx

		; update the values
		add eax, 0x400000
		add ebx, 0x400000
	loop .PageLoop


	.Exit:
	%undef pageDirPtr
	%undef virtualPtr
	%undef physicalPtr
	%undef pageCount
	%undef inputFlags
	%undef flagMask
	mov esp, ebp
	pop ebp
ret 20





section .text
PagingDirNew:
	; Creates a new empty page directory
	;
	;  input:
	;	Flags
	;
	;  output:
	;	ESI - Address of new page directory
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define inputFlags							dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define pageDirPtr							dword [ebp - 4]


	; get a page of RAM
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov pageDirPtr, eax

	; load input flags and set flags appropriately
	mov ebx, inputFlags

	; Force flags off to select the following:
	; bit 8 - This bit is ignored anyway
	; bit 6 - This bit must be zero
	; bit 0 - not present (since this is a new empty page dir and all)
	and ebx, 00000000000000000000000000011110b

	; Force flags on to select the following:
	; bit 7 - 4 MiB pages
	; bit 4 - Cache disabled (for now, to simplify debugging)
	; bit 3 - Write-through caching
	or ebx, 00000000000000000000000010011000b


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
	%undef inputFlags
	%undef pageDirPtr
	mov esp, ebp
	pop ebp
ret 4



; test code
jmp pagingdone
; create a page dir
push dword PDEBigPage + PDECacheDisable + PDEWriteThrough + PDEUserAccessable + PDEWritable
call PagingDirNew
mov [pagediraddr], esi

; load the page dir address
mov cr3, esi


; map some pages
push dword PDEBigPage + PDECacheDisable + PDEWriteThrough + PDEUserAccessable + PDEWritable
push dword 0x400
push dword 0x00000000
push dword 0x00000000
push dword [pagediraddr]
call PagingMap

; enable paging
mov eax, cr0
or eax, 0x80000000
mov cr0, eax

mov esi, [pagediraddr]
jmp $

push dword 0x0000009E
push dword 1
push dword 0x00800000
push dword 0x10000000
push dword [pagediraddr]
call PagingMap

push dword 0x0000009E
push dword 1
push dword 0xFFC00000
push dword 0xFFC00000
push dword [pagediraddr]
call PagingMap


mov esp, 0x300000




; test writing
mov esi, 0x200000
mov dword [esi], 0xc0de

mov esi, 0x10000000
mov dword [esi], 0xbeef

; disable paging
mov eax, cr0
;and eax, 01111111111111111111111111111111b
mov cr0, eax


mov esi, [pagediraddr]
jmp pagingdone

pagediraddr  dd 0x00000000


pagingdone:

