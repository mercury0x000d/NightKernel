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
; MemProbe						Probes the BIOS memory map using interrupt 0x15:0xE820, finds the largest block of free RAM, and fills in the appropriate system data structures for future use by the memory manager

; 32-bit function listing:
; MemAllocate					Returns the address of a memory block of the requested size, or zero if unavailble
; MemCompare					Compares two regions in memory of a specified length for equality
; MemCopy						Copies the specified number of bytes from one address to another
; MemDispose					Notifies the memory manager that the block specified by the address given is now free for reuse
; MemFill						Fills the range of memory given with the byte value specified
; MemInit						Inititlizes the Memory Manager
; MemResize						Resizes the specified block of RAM to the new size specified
; MemSearchWord					Searches the memory range specified for the given word value
; MemSearchDWord				Searches the memory range specified for the given dword value
; MemSearchString				Searches the memory range specified for the given string
; MemSwapWordBytes				Swaps the bytes in a series of words starting at the address specified
; MemSwapWordBytes				Swaps the words in a series of dwords starting at the address specified



; tMemoryInfo, for the physical memory allocator to track blocks
%define tMemInfo.address						(esi + 00)
%define tMemInfo.size							(esi + 04)
%define tMemInfo.task							(esi + 08)



bits 16



MemProbe:
	; Probes the BIOS memory map using interrupt 0x15:0xE820, finds the largest block of free RAM,
	; and fills in the appropriate system data structures for future use by the memory manager
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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
			mov dword [tSystem.listMemory], eax

		.SkipCheckBlock:
		; check to see if we're done with the loop
		cmp ebx, 0x00
		je .Done
	jmp .ProbeLoop

	.Done:

	mov sp, bp
	pop bp
ret
.memoryMapLabels$								db '   Address            Size               Type', 0x00



bits 32



MemAllocate:
	; Returns the address of a memory block of the requested size, or zero if unavailble
	;
	;  input:
	;	requesting task number
	;	requested memory size in bytes
	;
	;  output:
	;	address of requested block, or zero if call fails

	; This function implements a best-fit algorithm to fulfill memory requests. Why best-fit? Because it's better at keeping larger
	; contiguous free blocks available and the additional overhead to implement it is no big deal to modern processors.

	push ebp
	mov ebp, esp

	; local variables
	sub esp, 4									; list index counter
	sub esp, 4									; block which is our current best candidate

	; clear the best candidate variable
	mov dword [ebp - 8], 0

	; set up a loop to step through all elements in the memory list
	; get number of elements in memory list and save it to our loop index counter
	push dword 0
	push dword [tSystem.listMemory]
	call LMElementCountGet
	pop ecx
	pop eax

	.MemoryListLoop:
		; store ecx to the loop counter variable
		mov dword [ebp - 4], ecx

		; get the address of the current element
		mov eax, dword [ebp - 4]
		dec eax
		push eax
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		pop esi
		; ignore error code
		pop eax

		; see if this block is free, 
		; if not, we go to the next block in the loop
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .NextIteration

		; see if the size of this block is big enough to meet the request
		; if not, we go to the next block in the loop
		mov eax, [tMemInfo.size]
		mov ebx, [ebp + 12]
		cmp eax, ebx
		jbe .NextIteration

			; it was adequate! let's make note of this block then continue looking for a more suitable one
			mov ecx, dword [ebp - 4]
			dec ecx
			mov dword [ebp - 8], ecx

		.NextIteration:
	
	mov ecx, dword [ebp - 4]
	loop .MemoryListLoop


	.FulfillRequest:
	; Here we do the heavy-lifting of handling this request. This is done by cloning the "best candidate" element we just found, then editing
	; the original to reflect a slightly lower amount of free space since we're trimming off of it to fulfill the memory request. The clone,
	; which gets created right next door to the original block, will get set to values which reflect the details of the memory we're taking away.

	; test to see if we have enough free space here to grow the memory list by one entry
	; the memory block represented by element 0 in the memory list is always the only one which borers the memory list data itself
	; this is why we're testing element 0 here
	push dword 0
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	; ignore error code
	pop eax

	cmp dword [tMemInfo.size], 12
	jb .CannotGrowList

	; also check that this block is free
	cmp dword [tMemInfo.task], 0
	jb .CannotGrowList

	; If we get here, the list has room to grow! And... grow. We. Shall.
	; clone the best candidate
	push dword [ebp - 8]
	push dword [tSystem.listMemory]
	call LMElementDuplicate

	; get the address of the "best candidate" element (the "original")
	push dword [ebp - 8]
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	; ignore error code
	pop eax

	; save the address and size of this block for later
	push dword [tMemInfo.address]
	push dword [tMemInfo.size]

	; shrink this block by the amount we're using
	mov eax, dword [tMemInfo.size]
	sub eax, [ebp + 12]
	mov dword [tMemInfo.size], eax


	; get the address of the new cloned element
	mov eax, dword [ebp - 8]
	inc eax
	push eax
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	; ignore error code
	pop eax

	; calculate the address using the values we saved earlier
	pop ebx
	pop eax
	mov edx, [ebp + 12]
	mov ecx, eax
	add ecx, ebx
	sub ecx, edx
	mov dword [tMemInfo.address], ecx

	; set the size
	mov eax, [ebp + 12]
	mov dword [tMemInfo.size], eax

	; set the requesting task field
	mov eax, [ebp + 8]
	mov dword [tMemInfo.task], eax


	; BUT WAIT! There's MORE!
	; Since we grew the memory list by one element, we now need to adjust the address and size of block 0 here
	push 0
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	; ignore error code
	pop eax

	; adjust address
	mov eax, dword [tMemInfo.address]
	add eax, 12
	mov dword [tMemInfo.address], eax

	; adjust size
	mov eax, dword [tMemInfo.size]
	sub eax, 12
	mov dword [tMemInfo.size], eax


	; prepare to return address of this block
	mov dword [ebp + 12], ecx
	jmp .Exit

	.CannotGrowList:
	; If we get here, we were unable to grow the memory list. And if we're can't track it, we can't allocate it! Fail.
	mov dword [ebp + 12], 0

	.Exit:
	mov esp, ebp
	pop ebp
ret 4



MemCompare:
	; Compares two regions in memory of a specified length for equality
	;
	;  input:
	;	region 1 address
	;	region 2 address
	;	comparison length
	;
	;  output:
	;	result
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
	; Copies the specified number of bytes from one address to another in a "left to right" manner (e.g. lowest address to highest)
	;
	;  input:
	;	source address
	;	destination address
	;	transfer length
	;
	;  output:
	;	n/a

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
	;	address of block (as provided by MemAlloc())
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; local variables
	sub esp, 4									; loop counter

	; set up a loop to step through all elements in the memory list for printing
	push dword 0
	push dword [tSystem.listMemory]
	call LMElementCountGet
	pop ecx
	pop eax
	dec ecx

	.MemorySearchLoop:

		; save the important stuff for later
		mov dword [ebp - 4], ecx

		; get the address of this element
		push ecx
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		pop esi
		; ignore error code
		pop eax

		; see if the address of this block matches the one we're trying to release
		mov eax, [ebp + 8]
		mov ebx, [tMemInfo.address]
		cmp eax, ebx
		jne .NextIteration

		; if we get here, the addresses match! let's mark the block free
		mov dword [tMemInfo.task], 0

		; try to condense the memory list
		push dword [ebp - 4]
		call MemMergeBlocks

		.NextIteration:
		; restore the important stuff
		mov ecx, dword [ebp - 4]
	loop .MemorySearchLoop

	mov esp, ebp
	pop ebp
ret



MemFill:
	; Fills the range of memory given with the byte value specified
	;
	;  input:
	;	address
	;	length
	;	byte value
	;
	;  output:
	;	n/a

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



MemInit:
	; Initialize the memory list
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; load up the address of our big block o' RAM
	mov esi, [tSystem.listMemory]

	; create a list with a single entry of 12 bytes (the size of a memory list element)
	push 12
	push 1
	push esi
	call LMListInit

	; get some values ready to load into our shiny new memory list
	; start with calculating the address to which we'll be writing
	mov esi, [tSystem.listMemory]
	add esi, 16

	; now calculate the address of the big free memory block we're describing
	mov ebx, [tSystem.listMemory]
	add ebx, 16
	add ebx, 12
	mov dword [tMemInfo.address], ebx

	; now calculate the new free size
	; initial free size - the size of the list
	mov eax, [tSystem.memoryInitialAvailableBytes]
	sub eax, 16
	sub eax, 12
	mov dword [tMemInfo.size], eax

	; and we set the task ID, which is 0 because it's free space
	mov dword [tMemInfo.task], 0

	; and exit!
	mov esp, ebp
	pop ebp
ret



MemMergeBlocks:
	; Merges any neighboring free memory list elements into the one specified
	;
	;  input:
	;	Memory list element number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; local variables
	sub esp, 4									; element number of lower block
	sub esp, 4									; element number of higher block
	sub esp, 4									; address of lower block memory list element
	sub esp, 4									; address of higher block memory list element

	; make sure the block passed is free and valid
	push dword [ebp + 8]
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	pop eax
	cmp eax, 0
	jne .Exit

	mov eax, [tMemInfo.task]
	cmp eax, 0
	jne .Exit

	; check the next higher block
	mov ecx, dword [ebp + 8]
	inc ecx
	push ecx
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	pop eax

	; check if there was an error, like maybe the element isn't valid
	cmp eax, 0
	jne .CheckLowerBlock

		; if we get here the block existed, so let's see if it is free
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .CheckLowerBlock

			; if we get here, the block was free, so let's condense!
			mov ecx, dword [ebp + 8]
			mov dword [ebp - 4], ecx
			inc ecx
			mov dword [ebp - 8], ecx
			call .MemCondenseMergeBlocks

	.CheckLowerBlock:
	; check the next lower block
	mov ecx, dword [ebp + 8]
	dec ecx
	push ecx
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	pop esi
	pop eax

	; check if there was an error, like maybe the element isn't valid
	cmp eax, 0
	jne .CheckLowerBlock

		; if we get here the block existed, so let's see if it is free
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .Exit

			; if we get here, the block was free, so let's condense!
			mov ecx, dword [ebp + 8]
			mov dword [ebp - 4], ecx
			dec ecx
			mov dword [ebp - 8], ecx
			call .MemCondenseMergeBlocks

	jmp .Exit

	.MemCondenseMergeBlocks:
		
		; make sure the elements are in the proper order
		mov esi, dword [ebp - 4]
		mov edi, dword [ebp - 8]
		cmp esi, edi
		jb .SkipRegisterSwap

			; swap the registers
			xchg esi, edi

		.SkipRegisterSwap:
		mov dword [ebp - 4], esi
		mov dword [ebp - 8], edi

		; get and save the address of the lower block
		push esi
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		pop esi
		pop eax
		mov dword [ebp - 12], esi

		; get and save the address of the higher block
		mov esi, dword [ebp - 8]
		push esi
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		pop esi
		pop eax
		mov dword [ebp - 16], esi

		; get size of higher block
		mov eax, dword [tMemInfo.size]

		; get size of lower block
		mov esi, dword [ebp - 12]
		mov ebx, dword [tMemInfo.size]

		; add the sizes together and write the result back into the lower block
		add eax, ebx
		mov dword [tMemInfo.size], eax

		; delete the higher block
		push dword [ebp - 8]
		push dword [tSystem.listMemory]
		call LMElementDelete
		pop eax
	ret

	.Exit:

	mov esp, ebp
	pop ebp
ret 4



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
	;	search range start
	;	search region length
	;	word for which to search
	;
	;  output:
	;	address of match (zero if not found)

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
	;	search range start
	;	search region length
	;	dword for which to search
	;
	;  output:
	;	address of match (zero if not found)

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
	;	search range start
	;	search region length
	;	address of string for which to search
	;
	;  output:
	;	address of match (zero if not found)

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
	;	source address
	;	number of words to process
	;
	;  output:
	;	n/a

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
	;	source address
	;	number of dwords to process
	;
	;  output:
	;	n/a

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
