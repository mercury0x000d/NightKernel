; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; memory.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; tMemoryInfo, for the physical memory allocator to track blocks
%define tMemInfo.address						(esi + 00)
%define tMemInfo.size							(esi + 04)
%define tMemInfo.task							(esi + 08)





bits 16





section .text
A20Check:
	; Checks status of the A20 line
	;
	;  input:
	;   n/a
	;
	;  output:
	;	DX - Result code
	;		High byte = 0 on success, non zero = fail
	;		Low byte = 0 if disabled, 1 if enabled

	push bp
	mov bp, sp

	; save ds and es since we'll be fiddling with them later
	push ds
	push es

	mov ax, 0x2402
	int 0x15

	; if ah = 0, the call succeeded and we can exit now
	cmp ah, 0
	jne .ManualCheck
		mov dx, ax
		jmp .Exit
	.ManualCheck:

	; the BIOS function isn't available, so we need to probe it manually
	xor ax, ax ; ax = 0
	mov es, ax
 
	not ax ; ax = 0xFFFF
	mov ds, ax
 
	mov di, 0x0500
	mov si, 0x0510
 
	mov al, byte [es:di]
	push ax
 
	mov al, byte [ds:si]
	push ax
 
	mov byte [es:di], 0x00
	mov byte [ds:si], 0xFF
 
	cmp byte [es:di], 0xFF
 
	pop ax
	mov byte [ds:si], al
 
	pop ax
	mov byte [es:di], al
 
	mov dx, false
	je .Exit
 
	mov dx, true
 

	.Exit:
	; restore the segment registers we saved in the beginning to avoid a freak out
	pop es
	pop ds

	mov sp, bp
	pop bp
ret





section .text
A20Enable:
	; Enables the A20 line using all methods in order
	; Since A20 support is critical, this code will print an error then intentionally hang if unsuccessful
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp


	; check if already enabled
	push word 0
	call A20Check

	cmp dx, true
	jne .NotPreenabled
		; if we get here, the A20 line is already enabled by... someone... or... something. Spooky! O.O
		push .A20AlreadyEnabled$
		call PrintIfConfigBits16
		jmp .Exit
	.NotPreenabled:


	; attempt BIOS method
	call A20EnableBIOS

	; check if it worked
	push word 0
	call A20Check

	cmp dx, true
	jne .BIOSFailed
		; if we get here, the Port 0xEE method succeeded
		push .BIOSSuccess$
		call PrintIfConfigBits16
		jmp .Exit
	.BIOSFailed:

	; print the fail
	push .BIOSFail$
	call PrintIfConfigBits16


	; attempt Port EE method
	call A20EnablePortEE

	; check if it worked
	push word 0
	call A20Check

	cmp dx, true
	jne .PortEEFailed
		; if we get here, the Port 0xEE method succeeded
		push .portEESuccess$
		call PrintIfConfigBits16
		jmp .Exit
	.PortEEFailed:

	; print the fail
	push .portEEFail$
	call PrintIfConfigBits16


	; attempt Fast A20 method
	call A20EnableFastA20

	; check if it worked
	push word 0
	call A20Check

	cmp dx, true
	jne .FastA20Failed
		; if we get here, the FastA20 method succeeded
		push .fastA20Success$
		call PrintIfConfigBits16
		jmp .Exit
	.FastA20Failed:

	; print the fail
	push .fastA20Fail$
	call PrintIfConfigBits16


	; attempt Keyboard Controller method
	call A20EnableKeyboardController

	; check if it worked
	push word 0
	call A20Check

	cmp dx, true
	jne .KeyboardControllerFailed
		; if we get here, the Port 0xEE method succeeded
		push .keyboardControllerSuccess$
		call PrintIfConfigBits16
		jmp .Exit
	.KeyboardControllerFailed:

	; print the fail
	push .keyboardControllerFail$
	call PrintIfConfigBits16


	; if we get here, everything failed!
	; Now we convey the sad, sad news
	push .A20Fail$
	call Print16

	; Since A20 support is critical, we intentionally hang if unsuccessful
	; a hard lockup should really get our point across
	jmp $

	.Exit:
	mov sp, bp
	pop bp
ret

section .data
.A20AlreadyEnabled$								db 'A20 is already enabled', 0x00
.BIOSFail$										db 'BIOS method failed', 0x00
.BIOSSuccess$									db 'BIOS method succeeded', 0x00
.portEEFail$									db 'Port EE method failed', 0x00
.portEESuccess$									db 'Port EE method succeeded', 0x00
.keyboardControllerFail$						db 'Keyboard controller method failed', 0x00
.keyboardControllerSuccess$						db 'Keyboard controller method succeeded', 0x00
.fastA20Fail$									db 'Fast A20 Enable method failed', 0x00
.fastA20Success$								db 'Fast A20 Enable method succeeded', 0x00
.A20Fail$										db 'Cannot start: All methods to enable A20 failed', 0x00





section .text
A20EnableBIOS:
	; Enables the A20 line using BIOS interrrupt 0x15
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp


	; ask the BIOS nicely, and it just may enable A20 for us
	mov ax, 0x2401
	int 0x15


	mov sp, bp
	pop bp
ret





section .text
A20EnableFastA20:
	; Enables the A20 line using the Fast A20 method
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp


	; attempt Fast A20 Enable
	in al, 0x92
	or al, 00000010b
	out 0x92, al


	mov sp, bp
	pop bp
ret





section .text
A20EnableKeyboardController:
	; Attempts to enables the A20 line using the keyboard controller method
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	call .ReadyWait
	mov al, 0xAD
	out 0x64, al

	call .ReadyWait
	mov al, 0xD0
	out 0x64, al

	call .OutputWait
	in al, 0x60
	push ax

	call .ReadyWait
	mov al, 0xD1
	out 0x64, al

	call .ReadyWait
	pop ax
	or al, 00000010b
	out 0x60, al

	call .ReadyWait
	mov al, 0xAE
	out 0x64, al

	call .ReadyWait


	mov sp, bp
	pop bp
ret

.OutputWait:
	; set up a loop to read from the keyboard's controller until output is available

	; "Good things come to those who wait... and death comes to those who wait too long!"
	; With that in mind, we better set a timeout on this operation so that we don't
	; get stuck in any nasty infinite loops
	mov cx, 0xC000
	.OutputTimeoutLoop:
		in al, 0x64
		test al, 00000001b
		jnz .OutputAvailable
	loop .OutputTimeoutLoop
	.OutputAvailable:
ret

.ReadyWait:
	; set up a loop to read from the keyboard's controller until output is available
	; If we wanted an infinite loop, we'd visit Apple Campus.
	mov cx, 0xC000
	.ReadyTimeoutLoop:
		in al, 0x64
		test al, 00000010b
		jnz .Ready
	loop .ReadyTimeoutLoop
	.Ready:
ret





section .text
A20EnablePortEE:
	; Enables the A20 line using the Port 0xEE method
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp


	; perform Port 0xEE Enable
	out 0xEE, al


	mov sp, bp
	pop bp
ret





section .text
MemProbe:
	; Probes the BIOS memory map using interrupt 0x15:0xE820, finds the largest block of free RAM,
	; and fills in the appropriate system data structures for later use by the memory manager
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp

	; allocate local variables
	sub sp, 64
	%define attributes							dword [bp - 48]
	%define lengthHigh							dword [bp - 52]
	%define lengthLow							dword [bp - 56]
	%define addressHigh							dword [bp - 60]
	%define addressLow							dword [bp - 64]

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
	mov byte [gTextColor], 7
	mov byte [gBackColor], 0
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
		mov ecx, lengthLow
		add dword [tSystem.memoryInstalledBytes], ecx

		; test the output to see what we've just found
		; Type 1 - Usable RAM
		; Type 2 - Reserved, unusable
		; Type 3 - ACPI reclaimable memory
		; Type 4 - ACPI NVS memory
		; Type 5 - Area containing bad memory
		mov ecx, dword attributes
		cmp ecx, 0x01
		jne .SkipCheckBlock

			; if we get here, there's a good block of available RAM
			; let's see if we've found a bigger block than the current record holder!
			mov eax, lengthLow
			cmp eax, dword [tSystem.memoryInitialAvailableBytes]
			jna .SkipCheckBlock

			; if we get here, we've found a new biggest block! YAY!
			mov dword [tSystem.memoryInitialAvailableBytes], eax
			mov eax, dword addressLow
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

section .data
.memoryMapLabels$								db '   Address            Size               Type', 0x00





bits 32





section .text
MemAddressAlign:
	; Returns the aligned version of the address specified, aligned as specified
	;
	;  input:
	;	Address to align
	;	Alignment value
	;
	;  output:
	;	EAX - Aligned address

	push ebp
	mov ebp, esp


	; calculate the aligned version of the address we just got
	; blockAddressAligned = (int(address / alignment) + 1) * alignment
	mov eax, dword [ebp + 8]
	mov edx, 0
	div dword [ebp + 12]

	; if there is a fractional part, we can add 1
	cmp edx, 0
	je .SkipAdd
		inc eax
	.SkipAdd:

	mov edx, 0
	mul dword [ebp + 12]


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
MemAddressToBlock:
	; Returns the block number referenced by the address specified
	;
	;  input:
	;	Block address
	;
	;  output:
	;	EAX - Element number of block
	;	EDX - Result
	;		true - Block was matched
	;		false - Block was not matched

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define loopCounter							dword [ebp - 4]


	; set up a loop to step through all elements in the memory list for printing
	push dword [tSystem.listMemory]
	call LMElementCountGet
	dec ecx

	.MemorySearchLoop:

		; save the important stuff for later
		mov loopCounter, ecx

		; get the address of this element
		push ecx
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		
		; if there was an error, we can exit now
		cmp edx, 0
		jne .FailedToMatch

		; see if the address of this block matches the one we're trying to release
		mov eax, [ebp + 8]
		mov ebx, [tMemInfo.address]
		cmp eax, ebx
		jne .NextIteration

		; if we get here, the addresses match! let's report back to the caller
		mov eax, loopCounter
		mov edx, true
		jmp .Exit

		.NextIteration:
		; restore the important stuff
		mov ecx, loopCounter
	loop .MemorySearchLoop


	.FailedToMatch:
	; if we get here, there was no match
	; time to go home with our tail between our legs
	mov eax, 0
	mov edx, false


	.Exit:
	mov esp, ebp
	pop ebp
ret





section .text
MemAllocate:
	; Returns the address of a memory block of the requested size, or zero if unavailble
	;
	;  input:
	;	Requesting task number
	;	Requested memory size in bytes
	;
	;  output:
	;	EAX - Address of requested block, or zero if call fails
	;	EDX - Result code

	; This function implements a best-fit algorithm to fulfill memory requests. Why best-fit? Because it's better at keeping larger
	; contiguous free blocks available and the additional overhead to implement it is no big deal to modern processors.

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define currentBestCandidate				dword [ebp - 4]


	; make sure the task number is valid (e.g. nonzero, since we use zero to denote a block that's free)
	; if this check wasn't done, a memory block could be allocated with a task value of 0, and the rest of the
	; memory manager calls would see the block as available for use, even though the calling task is using it
	; As you can imagine, this is a Certified Very Bad Thing.
	cmp dword [ebp + 8], 0
	je .Exit

	push dword [ebp + 12]
	call MemFindMostSuitable
	mov currentBestCandidate, eax

	; see if we actually got anything
	cmp edx, true
	jne .Fail

	; Below we do the heavy-lifting of handling this request. This is done by cloning the "best candidate" element we just found,
	; then editing the original to reflect a slightly lower amount of free space since we're trimming off of it to fulfill the
	; memory request. The clone, which gets created right after the original block in the memory list, will get set to values
	; which reflect the details of the memory we're taking away.

	; grow the memory list
	push currentBestCandidate
	call Mem_Internal_MemListGrow

	; test for error
	cmp edx, true
	jne .Fail

	; get the address of the "best candidate" element (the "original")
	push currentBestCandidate
	push dword [tSystem.listMemory]
	call LMElementAddressGet

	; save the address and size of this block for later
	push dword [tMemInfo.address]
	push dword [tMemInfo.size]

	; shrink this block by the amount we're using
	mov eax, dword [tMemInfo.size]
	sub eax, [ebp + 12]
	mov dword [tMemInfo.size], eax

	; see if this block's size now = 0 and delete it if necessary
	cmp eax, 0
	jne .BlockSizeNotZero
		; if we get here, the element needs deleted since it's empty 
		push currentBestCandidate
		push dword [tSystem.listMemory]
		call LMElementDelete
		dec currentBestCandidate
	.BlockSizeNotZero:

	; get the address of the new cloned element
	mov eax, currentBestCandidate
	inc eax
	push eax
	push dword [tSystem.listMemory]
	call LMElementAddressGet

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
	mov ebx, [ebp + 8]
	mov dword [tMemInfo.task], ebx

	; prepare to return address of this block
	push ecx

	; we don't want to hand out blocks that are all dirtied up with old data
	push 0x00000000
	push eax
	push ecx
	call MemFill

	; reload the address and exit
	pop eax
	mov edx, 0
	jmp .Exit


	.Fail:
	; If we get here, we had a problem, Houston. Fail. Fail fail. The failiest fail in Failtown fail.
	mov eax, 0
	mov edx, 0	; this should obviously be an error code later on


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
MemAllocateAligned:
	; Returns the address of a memory block of the requested size aligned to the value specified, or zero if unavailble
	;
	;  input:
	;	Requesting task number
	;	Requested memory size in bytes
	;	Alignment necessary
	;
	;  output:
	;	EAX - Address of requested block, or zero if call fails
	;	EDX - Result code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 20
	%define blockAddress						dword [ebp - 4]
	%define blockAddressAligned					dword [ebp - 8]
	%define blockLeadingSize					dword [ebp - 12]
	%define blockTrailingSize					dword [ebp - 16]
	%define blockRequestedSize					dword [ebp - 20]

	; make sure alignment is 2 or greater to avoid both wasted time (1) and division by zero errors (0)
	cmp dword [ebp + 16], 2
	jb .Exit

	; first, simply try allocating a block normally. never know... we may happen to get one that's already at an aligned address!
	push dword [ebp + 12]
	push dword [ebp + 8]
	call MemAllocate
	mov blockAddress, eax

	; make sure we didn't get a bad block
	cmp blockAddress, 0
	jne .BlockValid1
		; if we get here, the block was invalid, e.g. out of memory
		mov edx, 0xFE00
		mov eax, 0
		jmp .Exit
	.BlockValid1:

	; see if the address we just got is aligned properly
	push dword [ebp + 16]
	push blockAddress
	call MemAddressAlign

	; check the result; if the two addresses match, we're good to exit now!
	cmp eax, blockAddress
	jne .NotAligned
		; if we get here, we happened to be aligned!
		mov edx, 0
		mov eax, blockAddress
		jmp .Exit
	.NotAligned:

	; if we get here, that last attempt didn't get us an aligned block
	; release it and start over
	push blockAddress
	call MemDispose

	; calculate the block size we'll need to allocate
	mov eax, dword [ebp + 12]
	add eax, dword [ebp + 16]
	mov blockRequestedSize, eax

	; allocate a block of sufficient size
	push eax
	push dword [ebp + 8]
	call MemAllocate
	mov blockAddress, eax

	; make sure we didn't get a bad block
	cmp blockAddress, 0
	jne .BlockValid2
		; if we get here, the block was invalid so we report an out of memory fail
		mov edx, 0xFE00
		mov eax, 0
		jmp .Exit
	.BlockValid2:

	; calculate the address inside this block which lies at the proper alignment
	push dword [ebp + 16]
	push blockAddress
	call MemAddressAlign
	mov blockAddressAligned, eax


	; calculate the size at the beginning of the block which leads upto the actual aligned address (leading space)
	mov ebx, blockAddress
	sub eax, ebx
	mov blockLeadingSize, eax

	; calculate the size at the end which we will be trimming off (trailing space)
	mov eax, blockRequestedSize
	sub eax, dword [ebp + 12]
	sub eax, blockLeadingSize
	mov blockTrailingSize, eax

	; if blockAddress = blockAddressAligned, then we happened to get a block that's already aligned
	; if they aren't equal, we need to trim both the leading and trailing space
	; if they are equal, we only need to trim the trailing space
	mov eax, blockAddressAligned
	mov ebx, blockAddress
	cmp eax, ebx
	je .TrimEnd

	; Trim the beginning then adjust blockAddress accordingly
	mov eax, blockRequestedSize
	sub eax, blockLeadingSize
	push dword eax
	push dword blockAddress
	call MemShrinkFromBeginning

	mov eax, blockAddress
	add eax, blockLeadingSize
	mov blockAddress, eax

	.TrimEnd:
	; Trim the end. duh.
	mov eax, blockRequestedSize
	sub eax, blockLeadingSize
	sub eax, blockTrailingSize
	push dword eax
	push dword blockAddress
	call MemShrinkFromEnd

	; set the return values and exit
	mov edx, 0
	mov eax, blockAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemCompare:
	; Compares two regions in memory of a specified length for equality
	;
	;  input:
	;	Region 1 address
	;	Region 2 address
	;	Comparison length
	;
	;  output:
	;	EDX - Result
	;		true - the regions are identical
	;		false - the regions are different

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, [ebp + 16]

	; set the result to possibly be changed if necessary later
	mov edx, false

	cmp ecx, 0
	je .Exit

	repe cmpsb
	jnz .Exit

	mov edx, true


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemCopy:
	; Copies the specified number of bytes from one address to another in a "left to right" manner (e.g. lowest address to highest)
	;
	;  input:
	;	Source address
	;	Destination address
	;	Transfer length
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
	je .Exit

	; and do the copy
	.ByteLoop:
		lodsb
		mov byte [edi], al
		inc edi	
	loop .ByteLoop


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemDispose:
	; Notifies the memory manager that the block specified by the address given is now free for reuse
	;
	;  input:
	;	Address of block (as provided by MemAllocate())
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define elementNum							dword [ebp - 4]


	; find which block number begins with this address
	push dword [ebp + 8]
	call MemAddressToBlock
	mov elementNum, eax

	; test for success
	cmp eax, true
	jne .Exit

	; get the address of this element
	push ecx
	push dword [tSystem.listMemory]
	call LMElementAddressGet

	; mark the block free
	mov dword [tMemInfo.task], 0

	; try to condense the memory list
	push dword elementNum
	call MemMergeBlocks


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
MemFill:
	; Fills the range of memory given with the byte value specified
	;
	;  input:
	;	Address
	;	Length
	;	Byte value
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

	.FillLoop:
		cmp esi, edi
		je .Exit
		mov byte [esi], bl
		inc esi
	jmp .FillLoop


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemFindMostSuitable:
	; Returns the element number of the most suitable free block for handling a request of the size specified
	;
	;  input:
	;	Size requested
	;
	;  output:
	;	EAX - Most suitable element
	;	EDX - Result
	;		true = A suitable block was found
	;		false = A suitable block was not found

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 16
	%define listIndexCounter					dword [ebp - 4]
	%define bestCandidateSlot					dword [ebp - 8]
	%define bestCandidateSize					dword [ebp - 12]
	%define exitCode							dword [ebp - 16]


	; clear the best candidate variable
	mov bestCandidateSlot, 0

	; default to false
	mov exitCode, false

	; set up a loop to step through all elements in the memory list
	; get number of elements in memory list and save it to our loop index counter
	push dword [tSystem.listMemory]
	call LMElementCountGet

	.MemoryListLoop:
		; store ecx to the loop counter variable
		mov listIndexCounter, ecx

		; get the address of the current element
		mov eax, listIndexCounter
		dec eax
		push eax
		push dword [tSystem.listMemory]
		call LMElementAddressGet

		; see if this block is free, 
		; if not, we go to the next block in the loop
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .NextIteration

		; see if the size of this block is big enough to meet the request
		; if not, we go to the next block in the loop
		mov eax, [tMemInfo.size]
		mov ebx, [ebp + 8]
		cmp eax, ebx
		jb .NextIteration

			; it was adequate! ONLY if we've already found a block should we check the sizing of this block
			; if we haven't found a block yet, it doesn't matter if we have a candidate yet or not
			mov exitCode, true
			jne .SkipSizeCheck
				; let's see if it's larger than the current best candidate and jump to the next iteration if so
				cmp eax, bestCandidateSize
				ja .NextIteration
			.SkipSizeCheck:


			; we got here, so let's make note of this block

			; note the slot number
			mov ecx, listIndexCounter
			dec ecx
			mov bestCandidateSlot, ecx

			; note the size of this free block
			mov bestCandidateSize, eax

			; set the flag that we did find something
			mov exitCode, true

	.NextIteration:
	mov ecx, listIndexCounter
	loop .MemoryListLoop

	; return what we found
	mov eax, bestCandidateSlot
	mov edx, exitCode


	mov esp, ebp
	pop ebp
ret 4





section .text
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

	; now calculate the value of the memoryListReservedSpace global (memory list max slots * size per slot + list header size)
	; get the element size of the memory list
	push dword [tSystem.listMemory]
	call LMElementSizeGet

	; multiply that value by how many list slots for which we're reserving space
	mov ebx, 8192
	mov edx, 0
	mul ebx

	; adjust for the list header
	add eax, 16

	; save this value
	mov dword [tSystem.memoryListReservedSpace], eax


	; start of free memory = address of free memory block + memoryListReservedSpace
	; add to that the starting address of this memory block
	add eax, dword [tSystem.listMemory]

	; and finally set the value we calculated into the list itself
	mov esi, [tSystem.listMemory]
	add esi, 16
	mov dword [tMemInfo.address], eax

	; now calculate the new free size
	; new free size = initial free size - the size of the list space reserved
	mov eax, [tSystem.memoryInitialAvailableBytes]
	sub eax, dword [tSystem.memoryListReservedSpace]
	mov dword [tMemInfo.size], eax

	; and we set the task ID, which is 0 because it's free space
	mov dword [tMemInfo.task], 0


	; and exit!
	mov esp, ebp
	pop ebp
ret





section .text
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

	; allocate 1 variables
	sub esp, 16
	%define lowerBlockElementNum				dword [ebp - 4]
	%define higherBlockElementNum				dword [ebp - 8]
	%define lowerBlockAddress					dword [ebp - 12]
	%define higherBlockAddress					dword [ebp - 16]


	; make sure the block passed is free and valid
	push dword [ebp + 8]
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	cmp edx, 0
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

	; check if there was an error, like maybe the element isn't valid
	cmp edx, 0
	jne .CheckLowerBlock

		; if we get here the block existed, so let's see if it is free
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .CheckLowerBlock

			; if we get here, the block was free, so let's condense!
			mov ecx, dword [ebp + 8]
			mov lowerBlockElementNum, ecx
			inc ecx
			mov higherBlockElementNum, ecx
			call .MemCondenseMergeBlocks

	.CheckLowerBlock:
	; check the next lower block
	mov ecx, dword [ebp + 8]
	dec ecx
	push ecx
	push dword [tSystem.listMemory]
	call LMElementAddressGet

	; check if there was an error, like maybe the element isn't valid
	cmp edx, 0
	jne .CheckLowerBlock

		; if we get here the block existed, so let's see if it is free
		mov eax, [tMemInfo.task]
		cmp eax, 0
		jne .Exit

			; if we get here, the block was free, so let's condense!
			mov ecx, dword [ebp + 8]
			mov lowerBlockElementNum, ecx
			dec ecx
			mov higherBlockElementNum, ecx
			call .MemCondenseMergeBlocks

	jmp .Exit

	.MemCondenseMergeBlocks:
		
		; make sure the elements are in the proper order
		mov esi, lowerBlockElementNum
		mov edi, higherBlockElementNum
		cmp esi, edi
		jb .SkipRegisterSwap

			; swap the registers
			xchg esi, edi

		.SkipRegisterSwap:
		mov lowerBlockElementNum, esi
		mov higherBlockElementNum, edi

		; get and save the address of the lower block
		push esi
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		mov lowerBlockAddress, esi

		; get and save the address of the higher block
		mov esi, higherBlockElementNum
		push esi
		push dword [tSystem.listMemory]
		call LMElementAddressGet
		mov higherBlockAddress, esi

		; get size of higher block
		mov eax, dword [tMemInfo.size]

		; get size of lower block
		mov esi, lowerBlockAddress
		mov ebx, dword [tMemInfo.size]

		; add the sizes together and write the result back into the lower block
		add eax, ebx
		mov dword [tMemInfo.size], eax

		; delete the higher block
		push higherBlockElementNum
		call Mem_Internal_MemListShrink

		; check for failure
		cmp edx, true
		je .AllGood

			; there was a failure, add code to handle it here
			; this is probably safe to ignore since we are using all good blocks here

		.AllGood:
	ret


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
MemSearchWord:
	; Searches the memory range specified for the given word value
	;
	;  input:
	;	Search range start
	;	Search region length
	;	Word for which to search
	;
	;  output:
	;	EAX - Address of match (zero if not found)

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov ebx, [ebp + 16]

	; preload the result
	mov eax, 0x00000000

	.MemorySearchLoop:
		; check if the word we just loaded is a match
		mov dx, [esi]
		cmp dx, bx
		je .MemorySearchLoopDone

		inc esi
	loop .MemorySearchLoop
	jmp .Exit

	.MemorySearchLoopDone:
	mov eax, esi


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemSearchDWord:
	; Searches the memory range specified for the given dword value
	;
	;  input:
	;	Search range start
	;	Search region length
	;	Dword for which to search
	;
	;  output:
	;	EAX - Address of match (zero if not found)

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]
	mov ecx, [ebp + 12]
	mov ebx, [ebp + 16]

	; preload the result
	mov eax, 0x00000000

	.MemorySearchLoop:
		; check if the dword we just loaded is a match
		mov edx, [esi]
		cmp edx, ebx
		je .MemorySearchLoopDone

		inc esi
	loop .MemorySearchLoop
	jmp .Exit

	.MemorySearchLoopDone:
	mov eax, esi


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemSearchString:
	; Searches the memory range specified for the given string
	;
	;  input:
	;	Search range start
	;	Search region length
	;	Address of string for which to search
	;
	;  output:
	;	EAX - Address of match (zero if not found)

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
	mov ebx, eax

	; exit if the string length is zero
	cmp eax, 0
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
		mov eax, false

		repe cmpsb
		jnz .LoopPhase2

		mov eax, true

		.LoopPhase2:
		; restore stuff again
		mov edi, [ebp + 16]
		mov esi, [ebp + 8]
		pop ecx
		pop ebx

		; decide if we have a match or not
		cmp eax, true
		mov eax, 0x00000000
		jne .NoMatch

		; if we get here, we found a match!
		mov eax, esi
		jmp .Exit

		.NoMatch:
		inc esi

	loop .MemorySearchLoop


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
MemShrinkFromBeginning:
	; Shrinks the block of memory specified to the size specified by trimming space off the beginning
	;
	;  input:
	;	Block address
	;	New size
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 16
	%define elementNum							dword [ebp - 4]
	%define elementAddress						dword [ebp - 8]
	%define newBlockAddress						dword [ebp - 12]
	%define newBlockSize						dword [ebp - 16]


	; locate the element which corresponds to this address
	push dword [ebp + 8]
	call MemAddressToBlock
	mov elementNum, eax

	; test for success
	cmp edx, true
	je .ElementFound
		; if we get here, the element could not be found, so we fail
		mov edx, 0xF000
		jmp .Exit
	.ElementFound:

	; get the address of this element so that we can do those tasty, tasty modifications ^_^
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	mov elementAddress, esi

	; check that the caller didn't specify a size larger than the original block (e.g. a grow instead of a shrink)
	mov eax, dword [ebp + 12]
	mov ebx, dword [tMemInfo.size]
	cmp eax, ebx
	jb .SizeIsValid
		; if we get here, the size was invalid
		mov edx, 0xF002
		jmp .Exit
	.SizeIsValid:

	; clone this element
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementDuplicate

	; test for errors
	cmp edx, 0
	je .DuplicateSuccessful
		; if we get here, the duplicate operation failed
		mov edx, 0xFE00
		jmp .Exit
	.DuplicateSuccessful:


	; now, to set all the proper values on the original block...
	; first, we can mark it as free
	mov esi, elementAddress
	mov dword [tMemInfo.task], 0

	; calculate and set the new size
	mov eax, [ebp + 12]
	mov ebx, dword [tMemInfo.size]
	sub ebx, eax
	mov newBlockSize, ebx
	mov eax, newBlockSize
	mov dword [tMemInfo.size], eax

	; and while we still have esi set for the original block, let's do a bit of calculation in advance
	; calculate the address for the new block ahead of time
	mov ebx, dword [tMemInfo.address]
	add ebx, eax
	mov newBlockAddress, ebx


	; get the address of the cloned element so that we can set its values
	inc elementNum
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementAddressGet

	; set the size
	mov eax, dword [ebp + 12]
	mov dword [tMemInfo.size], eax

	; set the address
	mov eax, newBlockAddress
	mov dword [tMemInfo.address], eax


	; try to condense the memory list
	dec elementNum
	push elementNum
	call MemMergeBlocks

	; if we get here, everything was successful!
	; set the return code and exit
	mov edx, 0


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
MemShrinkFromEnd:
	; Shrinks the block of memory specified to the size specified by trimming space off the end
	;
	;  input:
	;	Block address
	;	New size
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 16
	%define elementNum							dword [ebp - 4]
	%define elementAddress						dword [ebp - 8]
	%define newBlockAddress						dword [ebp - 12]
	%define newBlockSize						dword [ebp - 16]


	; locate the element which corresponds to this address
	push dword 0
	push dword [ebp + 8]
	call MemAddressToBlock
	mov elementNum, eax

	; test for success
	cmp edx, true
	je .ElementFound
		; if we get here, the element could not be found, so we fail
		mov edx, 0xF000
		jmp .Exit
	.ElementFound:

	; get the address of this element so that we can modify it
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementAddressGet
	mov elementAddress, esi

	; check that the caller didn't specify a size larger than the original block (e.g. a grow instead of a shrink)
	mov eax, dword [ebp + 12]
	mov ebx, dword [tMemInfo.size]
	cmp eax, ebx
	jb .SizeIsValid
		; if we get here, the size was invalid
		mov edx, 0xF002
		jmp .Exit
	.SizeIsValid:

	; calculate the new size of the block
	mov esi, elementAddress
	mov eax, [ebp + 12]
	mov ebx, dword [tMemInfo.size]
	sub ebx, eax
	mov newBlockSize, ebx

	; calculate the address the cloned block will have
	mov ebx, dword [tMemInfo.address]
	add ebx, eax
	mov newBlockAddress, ebx

	; set the size of the original block
	mov eax, dword [ebp + 12]
	mov dword [tMemInfo.size], eax

	; clone this element
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementDuplicate

	; test for errors
	cmp edx, 0
	je .DuplicateSuccessful
		; if we get here, the duplicate operation failed
		mov edx, 0xFE00
		jmp .Exit
	.DuplicateSuccessful:

	; get the address of the cloned element
	inc elementNum
	push elementNum
	push dword [tSystem.listMemory]
	call LMElementAddressGet

	; set the size of the cloned block
	mov eax, newBlockSize
	mov dword [tMemInfo.size], eax

	; set the address of the cloned block
	mov eax, newBlockAddress
	mov dword [tMemInfo.address], eax

	; mark the new block as free
	mov dword [tMemInfo.task], 0

	; try to condense the memory list
	push elementNum
	call MemMergeBlocks

	; if we get here, everything was successful!
	mov edx, 0


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
MemSwapWordBytes:
	; Swaps the bytes in a series of words starting at the address specified
	;
	;  input:
	;	Source address
	;	Number of words to process
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





section .text
MemSwapDwordWords:
	; Swaps the words in a series of dwords starting at the address specified
	;
	;  input:
	;	Source address
	;	Number of dwords to process
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





section .text
Mem_Internal_MemListGrow:
	; Adds an element to the list itself and duplicates the element specified
	;
	;  input:
	;	Element to duplicate during grow
	;
	;  output:
	;	EDX - Result
	;		true - Grow was successful
	;		false - Grow was unsuccessful

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define blockAddress						dword [ebp - 4]


	; clone the block we were given
	push dword [ebp + 8]
	push dword [tSystem.listMemory]
	call LMElementDuplicate

	; see if there was an error, although there shouldn't be
	cmp edx, 0
	jne .Fail

	; if we get here, all was good!
	mov edx, true
	jmp .Exit


	.Fail:
	mov edx, false


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
Mem_Internal_MemListShrink:
	; Subtracts an element from the list itself and deletes that element
	;
	;  input:
	;	Element to remove during shrink
	;
	;  output:
	;	EDX - Result
	;		true - Shrink was successful
	;		false - Shrink was unsuccessful

	push ebp
	mov ebp, esp

	; allocate local variables
 	sub esp, 4
	%define blockAddress						dword [ebp - 4]


	; next step, let's delete the block the caller specified
	push dword [ebp + 8]
	push dword [tSystem.listMemory]
	call LMElementDelete

	; see if there was an error, although there shouldn't be
	cmp edx, 0
	jne .Fail

	; if we get here, all was good!
	mov edx, true
	jmp .Exit


	.Fail:
	mov edx, false


	.Exit:
	mov esp, ebp
	pop ebp
ret












PageDirInit:
	; 
	;
	;  input:
	;	
	;
	;  output:
	;	

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define something							dword [ebp - 4]





	mov esp, ebp
	pop ebp
ret





PageDirBuildTo:
	; Builds up an existing page directory to the amount of memory specified
	;
	;  input:
	;	Page directory address
	;	Amount of memory to which the directory will be built
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define something							dword [ebp - 4]





	mov esp, ebp
	pop ebp
ret
