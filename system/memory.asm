; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; memory.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 16-bit function listing:
; MemoryInit					Probes the BIOS memory map using interrupt 0x15:0xE820, finds the largest block of free RAM, and fills in the appropriate system data structures for future use by the memory manager

; 32-bit function listing:
; MemAllocate					Returns the address of a block of memory of the specified size, or zero if a block of that size is unavailble
; MemCompare					Compares two regions in memory of a specified length for equality
; MemCopy						Copies the specified number of bytes from one address to another
; MemDispose					Notifies the memory manager that the block specified by the address given is now free for reuse
; MemFill						Fills the range of memory given with the byte value specified
; MemResize						Resizes the specified block of RAM to the new size specified
; MemSearchWord					Searches the memory range specified for the given word value
; MemSearchDWord				Searches the memory range specified for the given dword value
; MemSearchString				Searches the memory range specified for the given string
; MemSwapWordBytes				Swaps the bytes in a series of words starting at the address specified
; MemSwapWordBytes				Swaps the words in a series of dwords starting at the address specified



bits 16



MemoryInit:
	; Probes the BIOS memory map using interrupt 0x15:0xE820, finds the largest block of free RAM,
	; and fills in the appropriate system data structures for future use by the memory manager
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp
	sub sp, 44
	sub sp, 4									; attributes
	sub sp, 4									; lengthHigh
	sub sp, 4									; lengthLow
	sub sp, 4									; addressHigh
	sub sp, 4									; addressLow

	; clear the string to all spaces
	mov cx, 44
	mov si, bp
	sub si, 44
	.OutputStringClearLoop:
		mov byte [si], 32
		inc si
	loop .OutputStringClearLoop

	; throw a null at the end of the string
	mov byte [bp - 1], 0
	; print the labels string if appropriate
	mov byte [textColor], 7
	mov byte [backColor], 0
	push .memoryMapLabels$
	call PrintIfConfigBits16

	.SkipLabelPrinting:

	mov ebx, 0x00000000							; set ebx index to zero to start the probing loop
	.ProbeLoop:
		mov eax, 0x0000E820						; eax needs to be 0xE820
		mov ecx, 20
		mov edx, 0x534D4150						; the magic value "SMAP"
		mov di, bp
		sub di, 64								; addressLow (start of buffer)
		int 0x15

		; display the memory mapping table if appropriate
		push bx
		mov eax, [tSystem.configBits]
		and eax, 000000000000000000000000000000010b
		cmp eax, 000000000000000000000000000000010b
		jne .SkipMemoryMapPrinting

		; if we get here, it's cool to print verbose data, so let's build some strings!
		; first we fill in the address section of the string
		mov cx, 8
		mov dx, 0
		.MemoryMapAddressPrintLoop:
			mov si, bp
			sub si, 64							; addressLow
			add si, cx
			dec si
			mov ax, [si]

			push cx
			mov si, bp
			sub si, 44							; point to the beginning of the output string
			add si, 3							; position in output string
			add si, dx
			push si
			push ax
			call ConvertByteToHexString16
			pop cx
			add dx, 2
		loop .MemoryMapAddressPrintLoop

		; fill in the length section
		mov cx, 8
		mov dx, 0
		.MemoryMapLengthPrintLoop:
			mov si, bp
			sub si, 56							; lengthLow
			add si, cx
			dec si
			mov ax, [si]

			push cx
			mov si, bp
			sub si, 44							; point to the beginning of the output string
			add si, 22							; position in output string
			add si, dx
			push si
			push ax
			call ConvertByteToHexString16
			pop cx
			add dx, 2
		loop .MemoryMapLengthPrintLoop

		; fill in the type section
		mov si, bp
		sub si, 48								; attributes
		mov ax, [si]

		push cx
		mov si, bp
		sub si, 44								; point to the beginning of the output string
		add si, 41								; position in output string
		push si
		push ax
		call ConvertByteToHexString16
		pop cx

		; print the string
		mov si, bp
		sub si, 44								; point to the beginning of the output string
		push si
		call Print16

		.SkipMemoryMapPrinting:
		pop bx

		; add the size of this block to the total counter in the system struct
		mov ecx, dword [bp - 56]				; lengthLow
		add dword [tSystem.memoryInstalledBytes], ecx

		; test the output to see what we've just found
		; Type 1 - Usable RAM
		; Type 2 - Reserved, unusable
		; Type 3 - ACPI reclaimable memory
		; Type 4 - ACPI NVS memory
		; Type 5 - Area containing bad memory
		mov ecx, dword [bp - 48]				; attributes
		cmp ecx, 0x01
		jne .SkipCheckBlock

			; if we get here, there's a good block of available RAM
			; let's see if we've found a bigger block than the current record holder!
			mov eax, dword [bp - 56]			; lengthLow
			cmp eax, dword [tSystem.memoryInitialAvailableBytes]
			jna .SkipCheckBlock

			; if we get here, we've found a new biggest block! YAY!
			mov dword [tSystem.memoryInitialAvailableBytes], eax
			mov eax, dword [bp - 64]			; addressLow
			mov dword [tSystem.memoryBlockAddress], eax

		.SkipCheckBlock:
		; check to see if we're done with the loop
		cmp ebx, 0x00
		je .Done
	jmp .ProbeLoop

	.Done:

	; add code here to set up space tracking

	mov sp, bp
	pop bp
ret
.memoryMapLabels$								db '   Address            Size               Type', 0x00



bits 32



MemAllocate:
	; Returns the address of a block of memory of the specified size, or zero if a block of that size is unavailble
	;
	;  input:
	;   requested memory size in bytes
	;
	;  output:
	;   address of requested block, or zero if call fails

	; This routine temporarily uses a "dummy" allocation scheme; it simply allocates the amount of RAM requested beginning at the start of
	; the largest block available according to the BIOS memory map and increases upward with no error checking whatsoever. This will allow
	; basic allocate calls to function for development purposes until the full physical memory manager is completed.

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]

	; see if nextAllocation is zero
	cmp dword [.nextAllocation], 0
	jne .DoAllocation

	; if we get here, nextAllocation = 0, so we init the value before using it
	mov eax, [tSystem.memoryBlockAddress]
	mov dword [.nextAllocation], eax

	.DoAllocation:
	mov eax, [.nextAllocation]
	mov dword [ebp + 8], eax
	add eax, ecx
	mov [.nextAllocation], eax

	; add code here to mark space tracking with what we just allocated


	mov esp, ebp
	pop ebp
ret
.nextAllocation									dd 0x00000000



MemCompare:
	; Compares two regions in memory of a specified length for equality
	;
	;  input:
	;   region 1 address
	;   region 2 address
	;   comparison length
	;
	;  output:
	;   result
	;		kTrue - the regions are identical
	;		kFalse - the regions are different

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, [ebp + 16]

	; set the result to possibly be changed if necessary later
	mov edx, dword [kFalse]

	cmp ecx, 0
	je .Exit

	repe cmpsb
	jnz .Exit

	mov edx, dword [kTrue]

	.Exit:
	mov dword [ebp + 16], edx

	mov esp, ebp
	pop ebp
ret 8



MemCopy:
	; Copies the specified number of bytes from one address to another
	;
	;  input:
	;   source address
	;   destination address
	;   transfer length
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, [ebp + 16]

	; to copy at top speed, we will break the copy operation into two parts
	; first, we'll see how many multiples of 16 need transferred, and do those in 16-byte chunks

	; divide by 8
	shr ecx, 3

	; make sure the loop doesn't get executed if the counter is zero
	cmp ecx, 0
	je .ChunkLoopDone

	; do the copy
	.ChunkLoop:
		; read 8 bytes in
		mov eax, [esi]
		add esi, 4
		mov ebx, [esi]
		add esi, 4

		; write them out
		mov [edi], eax
		add edi, 4
		mov [edi], ebx
		add edi, 4
	loop .ChunkLoop
	.ChunkLoopDone:

	; now restore the transfer amount
	mov ecx, [ebp + 16]

	; see how many bytes we have remaining
	and ecx, 0x00000007

	; make sure the loop doesn't get executed if the counter is zero
	cmp ecx, 0
	je .ByteLoopDone

	; and do the copy
	.ByteLoop:
		lodsb
		mov byte [edi], al
		inc edi	
	loop .ByteLoop
	.ByteLoopDone:

	mov esp, ebp
	pop ebp
ret 12



MemDispose:
	; Notifies the memory manager that the block specified by the address given is now free for reuse
	;
	;  input:
	;   starting address of block (obtained with MemoryGet)
	;
	;  output:
	;   n/a

	
ret



MemFill:
	; Fills the range of memory given with the byte value specified
	;
	;  input:
	;   address
	;   length
	;   byte value
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov ebx, [ebp + 16]

	mov edi, esi
	add edi, ecx

	.Loop:
		cmp esi, edi
		je .LoopDone
		mov byte [esi], bl
		inc esi
	jmp .Loop
	.LoopDone:

	mov esp, ebp
	pop ebp
ret 12



MemResize:
	; Resizes the specified block of RAM to the new size specified
	;
	;  input:
	;	
	;
	;  output:
	;   

	
ret



MemSearchWord:
	; Searches the memory range specified for the given word value
	;
	;  input:
	;   search range start
	;   search region length
	;   word for which to search
	;
	;  output:
	;   address of match (zero if not found)

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov ebx, [ebp + 16]

	; preload the result
	mov edx, 0x00000000

	.MemorySearchLoop:
		; check if the dword we just loaded is a match
		mov ax, [esi]
		cmp ax, bx
		je .MemorySearchLoopDone

		inc esi
	loop .MemorySearchLoop
	jmp .Exit

	.MemorySearchLoopDone:
	mov edx, esi

	.Exit:
	mov dword [ebp + 16], edx

	mov esp, ebp
	pop ebp
ret 8



MemSearchDWord:
	; Searches the memory range specified for the given dword value
	;
	;  input:
	;   search range start
	;   search region length
	;   dword for which to search
	;
	;  output:
	;   address of match (zero if not found)

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov ebx, [ebp + 16]

	; preload the result
	mov edx, 0x00000000

	.MemorySearchLoop:
		; check if the dword we just loaded is a match
		mov eax, [esi]
		cmp eax, ebx
		je .MemorySearchLoopDone

		inc esi
	loop .MemorySearchLoop
	jmp .Exit

	.MemorySearchLoopDone:
	mov edx, esi

	.Exit:
	mov dword [ebp + 16], edx

	mov esp, ebp
	pop ebp
ret 8



MemSearchString:
	; Searches the memory range specified for the given string
	;
	;  input:
	;   search range start
	;   search region length
	;   address of string for which to search
	;
	;  output:
	;   address of match (zero if not found)

	; this code is SUCH a kludge
	; do everyone a favor and REWRITE THIS

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov edi, [ebp + 16]

	; get string length
	push edi
	call StringLength
	pop ebx

	; exit if the string lenght is zero
	cmp ebx, 0
	je .Exit

	; restore crucial stuff
	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov edi, [ebp + 16]

	; preload the result
	mov eax, 0x00000000

	.MemorySearchLoop:
		; save stuff again
		push ebx
		push ecx

		; see if this address is a match
		mov ecx, ebx

		; set the result to possibly be changed if necessary later
		mov eax, dword [kFalse]

		repe cmpsb
		jnz .Exit2

		mov eax, dword [kTrue]

		.Exit2:

		; restore stuff again
		mov edi, [ebp + 16]
		mov esi, [ebp + 8]
		pop ecx
		pop ebx

		; decide if we have a match or not
		cmp eax, [kTrue]
		mov eax, 0x00000000
		jne .NoMatch

		; if we get here, we found a match!
		mov eax, esi
		jmp .Exit

		.NoMatch:
		inc esi

	loop .MemorySearchLoop

	.Exit:
	mov dword [ebp + 16], eax

	mov esp, ebp
	pop ebp
ret 8



MemSwapWordBytes:
	; Swaps the bytes in a series of words starting at the address specified
	;
	;  input:
	;   source address
	;   number of words to process
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]

	.SwapLoop:
		mov ax, [esi]
		ror ax, 8
		mov [esi], ax
		add esi, 2
	loop .SwapLoop

	mov esp, ebp
	pop ebp
ret 8



MemSwapDwordWords:
	; Swaps the words in a series of dwords starting at the address specified
	;
	;  input:
	;   source address
	;   number of dwords to process
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]

	.SwapLoop:
		mov eax, [esi]
		ror eax, 16
		mov [esi], eax
		add esi, 4
	loop .SwapLoop

	mov esp, ebp
	pop ebp
ret 8
