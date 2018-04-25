; Night Kernel
; Copyright 1995 - 2018 by mercury0x000d
; memory.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



bits 16



MemoryInit:
	; Sets up all data structures which will be used by the memory manager
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	; determine available memory

	; write memory manager globals
	.starte820:

	xor ebx, ebx								;ebx needs to be set to 0
	xor bp, bp									;an entry count..........
	mov edx, 0x0534D4150						;smap needs to be set into edx
	mov eax, 0xE820								;eax needs to be E820
	mov [es:di + 20], dword 1					; so we are forcing a valid ACPI here
	mov ecx, 24									;ask for 24 bytes
	int 0x15									;call the int
	jc short .failed
	mov edx, 0x0534D4150
	cmp eax, edx								;eax gets reset to the 'smap' and edx is already that, so...
	jne short .failed
	test ebx, ebx								;if ebx = 0 we failed, if ebx = 0 it's 1 entry long.
	je short .failed
	jmp short .next

	.e820Continue:
	mov eax, 0xe820								;eax gets overwritten every time
	mov [es:di + 20], dword 1
	mov ecx, 24									;ecx gets overwritten as well
	int 0x15
	jc short .e820f
	mov edx, 0x0534D4150						;repair the trashed register

	.next:
	jcxz .skipentry								;skip the entry which are 0 long
	cmp cl, 20									;did we got a 24 byte ACPI response
	jbe short .notext
	test [es:di + 20], DWORD 1					;if that's true is the ignore data bit clear
	je short .skipentry

	.notext:
	mov ecx, [es:di + 8]						;get the lower memory region length
	or ecx, [es:di + 12]						;or test for zero
	jz .skipentry

	.skipentry:
	test ebx, ebx								;if it resets to 0 the list is done
	jne short .e820Continue

	.e820f:
	mov [memmap_ent], bp						;store the entry count
	clc											;clear the carry
	ret

	.failed:									;function unsupported
	stc
	mov byte [textColor], 0
	mov byte [backColor], 4
	push memE820Unsupported$
	call Print16
	call PrintRegs16
	jmp $

	memmap_ent db 0
ret



bits 32



MemAllocate:
	; Returns the address of a block of memory of the specified size, or zero if a block of that size is unavailble
	;  input:
	;   requested memory size in bytes
	;
	;  output:
	;   address of requested block, or zero if call fails

	; This routine temporarily uses a "dummy" allocation scheme; it simply allocates the amount of RAM requested beginning
	; at the 2 MB mark and increasing upward with no error checking whatsoever. This will allow basic allocate calls to
	; function for development purposes until the full paged memory manager is completed.

	pop edx
	pop ecx

	mov eax, [.nextAllocation]
	push eax
	add eax, ecx
	mov [.nextAllocation], eax
	push edx
ret
.nextAllocation									dd 0x00200000



MemCopy:
	; Copies the specified number of bytes from one address to another
	;  input:
	;   source address
	;   destination address
	;   transfer length
	;
	;  output:
	;   n/a
	;
	; changes: eax, ecx, esi, edi

	pop eax
	pop esi
	pop edi
	pop ecx
	push eax

	.MemCopyLoop:
		lodsb
		mov byte [edi], al
		inc edi
	loop .MemCopyLoop
ret



MemDispose:
	; Notifies the memory manager that the block specified by the address given is now free for reuse
	;  input:
	;   starting address of block (obtained with MemoryGet)
	;
	;  output:
	;   n/a
	;
	; changes: eax, ebx, ecx, edx, esi, edi

ret



MemFill:
	; Fills the range of memory given with the byte value specified
	;  input:
	;   starting fill address
	;   fill length
	;   fill character
	;
	;  output:
	;   n/a
	;
	; changes: ebx, ecx, esi, edi

	pop edi
	pop esi
	pop ecx
	pop ebx
	push edi

	mov edi, esi
	add edi, ecx

	.Loop:
		cmp esi, edi
		je .LoopDone
		mov byte [esi], bl
		inc esi
	jmp .Loop
	.LoopDone:
ret



MemResize:
	; Resizes the specified block of RAM to the new size specified
	;  input:
	;	
	;
	;  output:
	;   
	;
	; changes: 

	
ret



MemSearchDWord:
	; Searches the memory range specified for the given dword value
	;  input:
	;   search range start
	;   search range end
	;   dword for which to search
	;
	;  output:
	;   n/a
	;
	; changes: eax, ebx, ecx, edx


	pop eax
	pop ecx
	pop edx
	pop ebx
	push eax

	.MemorySearchLoop:
		; check if the dword we just loaded is a match
		mov eax, [ecx]
		cmp eax, ebx
		je .MemorySearchLoopDone
		; check if we're at the end of the search range
		cmp ecx, edx
		je .MemorySearchLoopDone
		inc ecx
	jmp .MemorySearchLoop
	.MemorySearchLoopDone:
ret



MemSearchWord:
	; Searches the memory range specified for the given word value
	;  input:
	;   search range start
	;   search range end
	;   word for which to search
	;
	;  output:
	;   n/a
	;
	; changes: eax, ebx, ecx, edx

	pop eax
	pop ecx
	pop edx
	pop ebx
	push eax

	.MemorySearchLoop:
		; check if the word we just loaded is a match
		mov word ax, [ecx]
		cmp ax, bx
		je .MemorySearchLoopDone
		; check if we're at the end of the search range
		cmp ecx, edx
		je .MemorySearchLoopDone
		inc ecx
	jmp .MemorySearchLoop
	.MemorySearchLoopDone:
ret



memE820Unsupported$								db 'Could not detect memory, function unsupported', 0x00