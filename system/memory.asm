; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; memory.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/memoryDefines.inc"

%include "include/boolean.inc"
%include "include/CPU.inc"
%include "include/globals.inc"
%include "include/errors.inc"
%include "include/lists.inc"
%include "include/numbers.inc"
%include "include/screen.inc"
%include "include/strings.inc"





bits 16





section .text
A20Check:
	; Checks status of the A20 line
	;
	;  input:
	;	n/a
	;
	;  output:
	;	DX - Result code
	;		High byte = 0 on success, non zero = fail
	;		Low byte = 0 if disabled, 1 if enabled


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
ret





section .text
A20Delay:
	; Enables the A20 line using all methods in order
	; Since A20 support is critical, this code will print an error then intentionally hang if unsuccessful
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; reset ticks to zero
	mov ah, 1
	mov cx, 0
	mov dx, cx
	int 0x1A


	; loop until 4 ticks (just under one fourth of a second) have passed
	.DelayLoop:
		mov ah, 0
		int 0x1A

		cmp dx, 4
	jb .DelayLoop

ret





section .text
A20Enable:
	; Enables the A20 line using all methods in order
	; Since A20 support is critical, this code will print an error then intentionally hang if unsuccessful
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; ; check if already enabled
	; call A20Check

	; cmp dx, true
	; jne .NotPreenabled
	; 	; if we get here, the A20 line is already enabled by... someone... or... something. Spooky! O.O
	; 	push .A20AlreadyEnabled$
	; 	call PrintIfConfigBits16
	; 	jmp .Exit
	; .NotPreenabled:


	; ; attempt BIOS method and wait
	; call A20EnableBIOS
	; call A20Delay

	; ; check if it worked
	; call A20Check
	; cmp dx, true
	; jne .BIOSFailed
	; 	; if we get here, the Port 0xEE method succeeded
	; 	push .BIOSSuccess$
	; 	call PrintIfConfigBits16
	; 	jmp .Exit
	; .BIOSFailed:

	; ; print the fail
	; push .BIOSFail$
	; call PrintIfConfigBits16


	; attempt Port EE method and wait
	call A20EnablePortEE
	call A20Delay

	; check if it worked
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


	; attempt Fast A20 method and wait
	call A20EnableFastA20
	call A20Delay

	; check if it worked
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


	; attempt Keyboard Controller method and wait
	call A20EnableKeyboardController
	call A20Delay

	; check if it worked
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
	;	n/a
	;
	;  output:
	;	n/a


	; ask the BIOS nicely, and it just may enable A20 for us
	mov ax, 0x2401
	int 0x15

ret





section .text
A20EnableFastA20:
	; Enables the A20 line using the Fast A20 method
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; attempt Fast A20 Enable
	in al, 0x92
	or al, 00000010b
	out 0x92, al

ret





section .text
A20EnableKeyboardController:
	; Attempts to enables the A20 line using the keyboard controller method
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


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

	jmp .Exit


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
		; set up a loop to read from the keyboard's controller until it is ready
		; If we wanted an infinite loop, we'd visit Cupertino.
		mov cx, 0xC000
		.ReadyTimeoutLoop:
			in al, 0x64
			test al, 00000010b
			jnz .Ready
		loop .ReadyTimeoutLoop
		.Ready:
	ret


	.Exit:
ret





section .text
A20EnablePortEE:
	; Enables the A20 line using the Port 0xEE method
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; perform Port 0xEE Enable
	in al, 0xEE

ret





section .text
MemMapCopy:
	; Copies the BIOS memory map to the segment specified by ES
	;
	;  input:
	;	n/a
	;
	;  output:
	;	AX - Entries copied
	;	DX - Error code

	push bp
	mov bp, sp

	; allocate local variables
	sub sp, 4
	%define entryCount							word [bp - 2]
	%define writePtr							word [bp - 4]


	; zero out the important stuff
	mov entryCount, 0
	mov writePtr, 0

	; a catalyst for the BIOS call
	mov ebx, 0

	.ProbeLoop:
		mov eax, 0x0000E820						; eax needs to be 0xE820
		mov ecx, 20
		mov edx, 'PAMS'							; the magic value "SMAP"
		mov di, writePtr
		int 0x15

		; see if there was an error
		mov edx, kErrMemoryInitFail
		cmp eax, 'PAMS'
		jne .Exit

		; adjust the write pointer
		add writePtr, 20

		; adjust the entry counter
		inc entryCount

		; check to see if we're done with the loop
		cmp ebx, 0x00
		je .Done
	jmp .ProbeLoop


	.Done:
	; save the memory map's size for later
	mov eax, 0
	mov ax, writePtr
	mov dword [tSystem.memoryBIOSMapSize], eax


	; no errors here!
	mov ax, entryCount
	mov dx, kErrNone


	.Exit:
	%undef entryCount
	%undef writePtr
	mov sp, bp
	pop bp
ret





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

	; define input parameters
	%define address								dword [ebp + 8]
	%define alignment							dword [ebp + 12]


	; calculate the aligned version of the address we just got
	; blockAddressAligned = (int(address / alignment) + 1) * alignment
	mov eax, address
	mov edx, 0
	div alignment

	; if there is a fractional part, we can add 1
	cmp edx, 0
	je .SkipAdd
		inc eax
	.SkipAdd:

	mov edx, 0
	mul alignment


	.Exit:
	%undef address
	%undef alignment
	mov esp, ebp
	pop ebp
ret 8





section .text
MemAllocate:
	; Returns the address of the first free memory block and marks it allocated in the memory management bitfield
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EAX - Address of requested block, or zero if call fails
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 8
	%define bitNumber							dword [ebp - 4]
	%define address								dword [ebp - 8]


	; get the first free block
	push 0
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitfieldScanClear
	cmp edx, kErrNone
	jne .Fail

	; make sure it's no more than 0xFFFFF since that's all we can directly deal with using 32-bit registers
	; 0xFFFFF * 0x1000 = 0xFFFFF000... one more page would be above 4 GiB
	cmp eax, 0xFFFFF
	ja .Fail

	; save the bit number for later
	mov bitNumber, eax

	; mark it allocated
	push eax
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitSet
	cmp edx, kErrNone
	jne .Fail

	; translate bit number to address and save for later
	mov eax, bitNumber
	shl eax, 12
	mov address, eax

	; zero out this memory block for security and sanity
	push 0x00
	push 4096
	push address
	call MemFill

	; and exit!
	mov eax, address
	mov edx, kErrNone
	jmp .Exit


	.Fail:
	; If we get here, we had a problem, Houston. Fail. Fail fail. The failiest fail in Failtown fail.
	mov eax, 0
	mov edx, kErrOutOfMemory

	.Exit:
	%undef bitNumber
	%undef address
	mov esp, ebp
	pop ebp
ret





section .text
MemAllocatePages:
	; Allocates the number of pages specified
	;
	;  input:
	;	Number of pages
	;
	;  output:
	;	EAX - Address of first requested block, or zero if call fails
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define pageCount							dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define address								dword [ebp - 4]


	; allocate a page
	call MemAllocate
	mov address, eax
	cmp edx, kErrNone
	jne .Exit

	mov ecx, pageCount
	dec ecx
	.AllocateLoop:
		mov pageCount, ecx

		; allocate a page
		call MemAllocate
		cmp edx, kErrNone
		jne .Exit

		mov ecx, pageCount
	loop .AllocateLoop

	; and exit!
	mov eax, address
	mov edx, kErrNone
	jmp .Exit


	.Exit:
	%undef bitNumber
	%undef address
	mov esp, ebp
	pop ebp
ret 4





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

	; define input parameters
	%define region1Ptr							dword [ebp + 8]
	%define region2Ptr							dword [ebp + 12]
	%define length								dword [ebp + 16]


	mov esi, region1Ptr
	mov edi, region2Ptr
	mov ecx, length

	; set the result to possibly be changed if necessary later
	mov edx, false

	cmp ecx, 0
	je .Exit

	repe cmpsb
	jnz .Exit

	mov edx, true


	.Exit:
	%undef region1Ptr
	%undef region2Ptr
	%undef length
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

	; define input parameters
	%define source								dword [ebp + 8]
	%define dest								dword [ebp + 12]
	%define length								dword [ebp + 16]


	; to copy at top speed, we will break the copy operation into parts
	; the most significant part will be using SSE2 if it's available
	push kCPU_sse2
	push tSystem.CPUFeatures
	call LMBitGet

	; set up the pointers and length mask before we decide the next branch regarding what we just found out about SSE support above
	mov esi, source
	mov edi, dest
	mov edx, 11111111111111111111111111111111b

	jnc .SSEBlockLoopDone


	; first, see how many multiples of 128 need transferred, and make sure the loop doesn't get executed if the result is zero
	mov ecx, length
	shr ecx, 7
	cmp ecx, 0
	je .SSEBlockLoopDone

	; do the copy
	.SSEBlockLoop:
		; read 128 bytes in
		movdqu xmm0, [esi]
		movdqu xmm1, [esi + 0x10]
		movdqu xmm2, [esi + 0x20]
		movdqu xmm3, [esi + 0x30]
		movdqu xmm4, [esi + 0x40]
		movdqu xmm5, [esi + 0x50]
		movdqu xmm6, [esi + 0x60]
		movdqu xmm7, [esi + 0x70]

		; write them out
		movdqu [edi], xmm0
		movdqu [edi + 0x10], xmm1
		movdqu [edi + 0x20], xmm2
		movdqu [edi + 0x30], xmm3
		movdqu [edi + 0x40], xmm4
		movdqu [edi + 0x50], xmm5
		movdqu [edi + 0x60], xmm6
		movdqu [edi + 0x70], xmm7

		add esi, 128
		add edi, 128
	loop .SSEBlockLoop
	mov edx, 00000000000000000000000001111111b

	.SSEBlockLoopDone:


	; divide length by 8 and skip the loop if the result is zero
	mov ecx, length
	and ecx, edx
	shr ecx, 3
	cmp ecx, 0
	je .ChunkLoopDone

	; do the copy
	.ChunkLoop:
		; read 8 bytes in
		lodsd
		mov ebx, [esi]

		; write them out
		stosd
		mov [edi], ebx

		; increment the counters
		add esi, 4
		add edi, 4
	loop .ChunkLoop
	.ChunkLoopDone:


	; now see how many bytes we have remaining
	mov ecx, length
	and ecx, 00000000000000000000000000000111b

	; make sure the loop doesn't get executed if the counter is zero
	cmp ecx, 0
	je .ByteLoopDone

	; and do the copy
	.ByteLoop:
		lodsb
		stosb
	loop .ByteLoop
	.ByteLoopDone:


	.Exit:
	%undef source
	%undef dest
	%undef length
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define elementNum							dword [ebp - 4]


	; if we have a misaligned address, throw an error
	mov eax, address
	and eax, 00000000000000000000111111111111b
	cmp eax, 0
	jne .Fail

	; convert address to bit number (bit number = address / 4096)
	mov eax, address
	shr eax, 12

	; mark the block free
	push eax
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitClear
	cmp edx, kErrNone
	jne .Fail

	jmp .Exit

	.Fail:
	mov edx, kErrInvalidParameter

	.Exit:
	%undef address
	%undef elementNum
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

	; define input parameters
	%define address								dword [ebp + 8]
	%define length								dword [ebp + 12]
	%define value								dword [ebp + 16]


	mov edi, address
	mov ebx, value

	; since we're processing DWords here first, ecx = length / 4
	mov ecx, length
	shr ecx, 2
	cmp ecx, 0
	je .DWordTransferDone
		; clone al to the remaining bytes in EAX
		; e.g. 0xBE becomes 0xBEBEBEBE, or 0xAA becomes 0xAAAAAAAA
		mov bh, bl
		mov ax, bx
		shl eax, 16
		mov ax, bx
		rep stosd
	.DWordTransferDone:


	; if the length was not evenly divisible by 4, we need to process the remaining bytes here
	mov ecx, length
	and ecx, 00000000000000000000000000000011b
	cmp ecx, 0
	je .ByteTransferDone
		mov al, bl
		rep stosb
	.ByteTransferDone:


	.Exit:
	%undef address
	%undef length
	%undef value
	mov esp, ebp
	pop ebp
ret 12





section .text
MemInit:
	; Initializes the memory bitfields
	;
	;  input:
	;	n/a
	;
	;  output:
	;	Error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 16
	%define memMapOffset						dword [ebp - 4]
	%define bitsNeededPerBitfield				dword [ebp - 8]
	%define entryLengthPtr						dword [ebp - 12]
	%define loopIndex							dword [ebp - 16]


	; calculate how many bits are needed to cover the address space in the machine and save to bitsNeededPerBitfield
	; bitsNeededPerBitfield = (address of highest-addressed entry in the map / 4096) + (length of highest-addressed entry in the map / 4096)
	mov memMapOffset, 0x80000
	mov bitsNeededPerBitfield, 0
	mov ecx, dword [tSystem.memoryBIOSMapEntryCount]
	.CeilingFindLoop:
		mov loopIndex, ecx

		; address calculation
		mov eax, ecx
		dec eax
		mov ebx, 20
		mul ebx
		mov esi, 0x80000
		add esi, eax
		mov memMapOffset, esi


		; shift the address and length to divide by 4096 (turns bytes into pages)
		; We must use our QuadShift routines here in case we have a machine which has over 4 GiB of RAM.
		; The normal registers just won't cut it, son!
		call .ShiftEntriesRight


		; calculate the highest address in the block of memory specified by this entry into EBX
		mov esi, memMapOffset
		mov ebx, [esi + tBIOSMemMapEntry.address]
		add ebx, [esi + tBIOSMemMapEntry.length]


		; see if this value is higher than the current record holder, if so replace it
		cmp ebx, bitsNeededPerBitfield
		jna .NotHigher
			mov bitsNeededPerBitfield, ebx
		.NotHigher:


		; put the address and length back the way they were - we'll need them in their original form later
		call .ShiftEntriesLeft


		mov ecx, loopIndex
	loop .CeilingFindLoop


	; Now we need to figure out where the memory management information will be stored. But how?? Memory management isn't fully set up yet!
	; A WILD SOLUTION APPEARS! It'll be super effective! :D
	; We step through the list and look for a spot that's appropriate to store the data we found. It has to be in the 32-bit address space
	; (e.g. under 4 GiB) and large enough to hold the two memory bitfields and the shadowed map data. 

	; So, first step; figure out how much space we need for one bitfield.
	push bitsNeededPerBitfield
	call LMBitfieldSpaceCalc
	mov [tSystem.memoryBitfieldSize], eax

	; Now tSystem.memoryBitfieldSize contains the amount of RAM used for a single bitfield, and there are two of them.
	; That's right, TWO bitfields. And why, pray tell, are there two bitfields?
	; pagesAllocated tracks which pages are allocated (0 if free, 1 if allocated).
	; pagesReserved tracks which pages are reserved (0 if usable, 1 if reserved).

	; total space = bitsNeededPerBitfield * 2 + tSystem.memoryBIOSMapSize
	shl eax, 1
	add eax, dword [tSystem.memoryBIOSMapSize]
	mov dword [tSystem.memoryManagementSpace], eax


	; Now that we know how much space is needed, it's time to step through the memory map and find a spot large enough to hold it.
	; The good news is that this will be the single most awkward allocation we will ever have to perform. It'll be much smoother from here on!
	mov memMapOffset, 0x80000
	mov ecx, dword [tSystem.memoryBIOSMapEntryCount]
	.MemSearchLoop:
		mov loopIndex, ecx

		; see if this entry is available RAM (Type 01)
		mov esi, memMapOffset
		mov ebx, dword [esi + tBIOSMemMapEntry.type]

		cmp ebx, 1
		jne .MemSearchLoopIterate

		; If we get here, the entry is for usable RAM. Let's see if it's big enough to hold what we need.
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.length
		mov ebx, [esi]

		cmp ebx, dword [tSystem.memoryManagementSpace]
		jb .MemSearchLoopIterate

		; Great, it's big enough! Now let's see if its starting address is in range. Technically, that range could be
		; anywhere from 1 MiB to 4 GiB, but we'll stay in the 1 MiB to 2 GiB (0x80000000) range just to be safe.
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.address
		mov ebx, [esi]

		; preemptively save the address for later, just in case
		mov dword [tSystem.memoryBitfieldAllocatedPtr], ebx

		push 0x80000000
		push 0x00100000
		push ebx
		call RangeCheck
		cmp al, 1
		jne .MemSearchLoopIterate

		; WOW! If we get here, we found what we're looking for! Now, to get out of this penny-ante loop and copy some memory. 8)
		jmp .MemSearchLoopDone

		.MemSearchLoopIterate:
		; increment the memMapOffset
		add memMapOffset, 20

		mov ecx, loopIndex
	loop .MemSearchLoop

	; If we get here, we're somehow running on a machine which has so little RAM that it doesn't even have space to track those same
	; precious few bytes. How does such a paradox exist? How did we even get this far in such a situation? Well I'm not sure, but such a
	; machine probably belongs someone aghast that a 32-bit DOS even exists. ^_^ 
	; Needless to say, this is an error condition. Consider printing a "It's time to upgrade your PC-XT." message.
	mov edx, kErrMemoryInitFail
	jmp .Exit


	.MemSearchLoopDone:
	; if we get here, we got a good block in which we can create a pair of bitfields and shadow the memory map

	; First, create said bitfields.
	push bitsNeededPerBitfield
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitfieldInit

	; calculate the address of the next bitfield
	mov eax, dword [tSystem.memoryBitfieldAllocatedPtr]
	add eax, [tSystem.memoryBitfieldSize]
	mov dword [tSystem.memoryBitfieldReservedPtr], eax

	; create bitfield #2
	push bitsNeededPerBitfield
	push dword [tSystem.memoryBitfieldReservedPtr]
	call LMBitfieldInit


	; the memory we just claimed may be dirty; force clean it
	push 0x00000000
	mov ecx, dword [tSystem.memoryBitfieldSize]
	sub ecx, 0x10
	push ecx
	mov esi, dword [tSystem.memoryBitfieldAllocatedPtr]
	add esi, 0x10
	push esi
	call MemFill

	push 0x00000000
	mov ecx, dword [tSystem.memoryBitfieldSize]
	sub ecx, 0x10
	push ecx
	mov esi, dword [tSystem.memoryBitfieldReservedPtr]
	add esi, 0x10
	push esi
	call MemFill


	; next, we calculate the destination address for the memory map data
	mov eax, dword [tSystem.memoryBitfieldAllocatedPtr]
	add ebx, [tSystem.memoryBitfieldSize]
	shl ebx, 1
	add eax, ebx

	; save that address to the system struct
	mov dword [tSystem.memoryBIOSMapPtr], eax

	; now we copy the BIOS memory map from 0x80000 to its spot in the memory management area
	push dword [tSystem.memoryBIOSMapSize]
	push eax
	push 0x80000
	call MemCopy


	; Now that they are both created, we set every. Single. Bit. Why? Because the memory map of this system likely has 1.5 metric crap-tons
	; of holes in it, and we don't want to allocate space in one of them in the future and upset the apple cart. Not the one in Cupertino - that
	; would've been the Apple(TM) Cart, or perhaps the iCart. It would cost twice as much as any other cart, hold half as much, and break in
	; two when dropped. But it's ok, because you get to feel superior to everyone else and you can buy an upgraded model next year which has the
	; exact same amount of carrying capacity yet somehow costs even more money.

	; mark the range as already allocated
	mov eax, bitsNeededPerBitfield
	dec eax
	push eax
	push dword 0
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitSetRange

	; mark the range as already allocated
	mov eax, bitsNeededPerBitfield
	dec eax
	push eax
	push dword 0
	push dword [tSystem.memoryBitfieldReservedPtr]
	call LMBitSetRange


	; Next, we parse the memory map to determine what gets marked as available. We do this by examining every entry at or above
	; the 1 MiB mark and clearing the corresponding bits in both bitfields. The algorithm employed to do so makes the assumption that every such
	; memory map entry will have a length which is an even multiple of 4 KiB, and I believe that is a safe assumption to make, as every real
	; machine which I have examined thus far (as well as VirtualBox) have all conformed to this pattern; not once did I see a memory entry at
	; or over 1 MiB which was not an even multiple of 4 KiB.

	; Init important... oh, you know the drill
	mov memMapOffset, 0x80000
	mov ecx, dword [tSystem.memoryBIOSMapEntryCount]

	.MemAvailableLoop:
		mov loopIndex, ecx
		; if this is not an entry for available RAM (Type 01) we can skip it
		mov esi, memMapOffset
		cmp dword [esi + tBIOSMemMapEntry.type], 1
		jne .MemAvailableLoopIterate

		; If we get here, the entry was for usable RAM
		; if this address exceeds the 32 bit space, we can skip the next check since it would be guaranteed to be over the 1 MiB mark
		cmp dword [esi + tBIOSMemMapEntry.address + 4], 0
		jne .MarkAvailable
			; If we get here, this address is in the 32-bit address space. Let's see if it's over a meg. If it is, we don't mark it available.
			cmp dword [esi + tBIOSMemMapEntry.address], 0x100000
			jb .MemAvailableLoopIterate
		.MarkAvailable:


		; if we get here, this memory range needs marked available; first, convert the 64-bit address and length to 32-bit "page" values
		call .ShiftEntriesRight

		; mark the range as available
		mov esi, memMapOffset
		mov eax, dword [esi + tBIOSMemMapEntry.address]
		add eax, dword [esi + tBIOSMemMapEntry.length]
		dec eax
		push eax
		push dword [esi + tBIOSMemMapEntry.address]
		push dword [tSystem.memoryBitfieldAllocatedPtr]
		call LMBitClearRange
		cmp edx, kErrNone
		jne .Exit

		; mark the range as not reserved
		mov esi, memMapOffset
		mov eax, dword [esi + tBIOSMemMapEntry.address]
		add eax, dword [esi + tBIOSMemMapEntry.length]
		dec eax
		push eax
		push dword [esi + tBIOSMemMapEntry.address]
		push dword [tSystem.memoryBitfieldReservedPtr]
		call LMBitClearRange
		cmp edx, kErrNone
		jne .Exit


		; convert the "page" values back to "byte" values since we'll need them intact for the next (and final!) loop
		call .ShiftEntriesLeft


		.MemAvailableLoopIterate:
		; increment the memMapOffset
		add memMapOffset, 20

		mov ecx, loopIndex
	loop .MemAvailableLoop


	; Next, we parse the memory map (again!) to determine what needs marked as reserved. We do this by examining every entry at or above
	; the 1 MiB mark and setting the corresponding bits in both bitfields. The algorithm employed to do so makes the same assumptions about the
	; memory map which the previous one did.

	; At this point, we have two copies of the BIOS memory map - one at the address denoted by tSystem.memoryBIOSMapPtr and the other
	; at 0x80000. Since the operation of this loop is destructive, we use the "old" copy of the map at 0x80000.

	; Init important... oh, you know the drill
	mov memMapOffset, 0x80000
	mov ecx, dword [tSystem.memoryBIOSMapEntryCount]

	.MemReservedLoop:
		mov loopIndex, ecx
		; if this is an entry for available RAM (Type 01) we can skip it
		mov esi, memMapOffset
		cmp dword [esi + tBIOSMemMapEntry.type], 1
		je .MemReservedLoopIterate

		; If we get here, the entry was not for usable RAM; if this address is greater than 32 bits, we can proceed
		cmp dword [esi + tBIOSMemMapEntry.address + 4], 0
		jne .MarkReserved
			; If we get here, this address is in the 32-bit address space. Let's see if it's under a meg. If it is, we skip it.
			cmp dword [esi + tBIOSMemMapEntry.address], 0x100000
			jb .MemReservedLoopIterate
		.MarkReserved:


		; if we get here, this memory range needs marked reserved; first, convert the 64-bit address and length to 32-bit "page" values
		call .ShiftEntriesRight


		; mark the range as allocated
		mov esi, memMapOffset
		mov eax, dword [esi + tBIOSMemMapEntry.address]
		add eax, dword [esi + tBIOSMemMapEntry.length]
		dec eax
		push eax
		push dword [esi + tBIOSMemMapEntry.address]
		push dword [tSystem.memoryBitfieldAllocatedPtr]
		call LMBitSetRange
		cmp edx, kErrNone
		jne .Exit

		; mark the range as reserved
		mov esi, memMapOffset
		mov eax, dword [esi + tBIOSMemMapEntry.address]
		add eax, dword [esi + tBIOSMemMapEntry.length]
		dec eax
		push eax
		push dword [esi + tBIOSMemMapEntry.address]
		push dword [tSystem.memoryBitfieldReservedPtr]
		call LMBitSetRange
		cmp edx, kErrNone
		jne .Exit


		.MemReservedLoopIterate:
		; increment the memMapOffset
		add memMapOffset, 20

		mov ecx, loopIndex
	loop .MemReservedLoop


	; here we save for later the amount of bits (pages) marked used in the allocated bitmap to aid in calculating free memory later
	mov esi, [tSystem.memoryBitfieldAllocatedPtr]
	mov eax, [esi + tBitfieldInfo.setCount]
	mov [tSystem.memoryBitsInitial], eax


	; Next, we have to mark the space occupied by these data structures as reserved as well. The total space occupied by everything we need
	; to manage memory (both bitfields and the shadowed BIOS memory map) is stored in dword [tSystem.memoryManagementSpace], so we first need
	; to convert that to a number of pages and save it for later (we can reuse bitsNeededPerBitfield for this).
	push dword [tSystem.memoryManagementSpace] 
	call MemPagesNeeded
	mov bitsNeededPerBitfield, eax

	; now convert the starting address (tSystem.memoryBitfieldAllocatedPtr) to a page / bit number / thingy
	; bit number = tSystem.memoryBitfieldAllocatedPtr / 4096
	mov ebx, dword [tSystem.memoryBitfieldAllocatedPtr]
	shr ebx, 12

	; mark the range as already allocated
	add eax, ebx
	dec eax
	push eax
	push ebx
	push dword [tSystem.memoryBitfieldAllocatedPtr]
	call LMBitSetRange
	cmp edx, kErrNone
	jne .Exit

	; mark the range as reserved
	mov ebx, dword [tSystem.memoryBitfieldAllocatedPtr]
	shr ebx, 12
	mov eax, bitsNeededPerBitfield
	add eax, ebx
	dec eax
	push eax
	push ebx
	push dword [tSystem.memoryBitfieldReservedPtr]
	call LMBitSetRange

	jmp .Exit


	.ShiftEntriesRight:
		push 12
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.address
		push esi
		call QuadShiftRight

		push 12
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.length
		push esi
		call QuadShiftRight
	ret


	.ShiftEntriesLeft:
		push 12
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.address
		push esi
		call QuadShiftLeft

		push 12
		mov esi, memMapOffset
		add esi, tBIOSMemMapEntry.length
		push esi
		call QuadShiftLeft
	ret


	; and exit!
	.Exit:
	mov esp, ebp
	pop ebp
	%undef memMapOffset
	%undef bitsNeededPerBitfield
	%undef entryLengthPtr
	%undef loopIndex
ret





MemMapPrint:
	; Prints the BIOS Memory Map
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 16
	%define loopIndex							dword [ebp - 4]
	%define entryNumber							dword [ebp - 8]
	%define memMapOffsetLow						dword [ebp - 12]
	%define memMapOffsetHigh					dword [ebp - 16]


	mov eax, 0x80000
	mov memMapOffsetLow, eax
	mov memMapOffsetHigh, eax
	add memMapOffsetHigh, 4

	mov entryNumber, 0

	push .memoryTable$
	call PrintIfConfigBits32

	mov ecx, [tSystem.memoryBIOSMapEntryCount]

	.MapLoop:
	mov loopIndex, ecx

		push 80
		push .scratch$
		push .mapFormat$
		call MemCopy

		push 2
		push entryNumber
		push .scratch$
		call StringTokenDecimal

		call .TokenTranslate

		add memMapOffsetHigh, 8
		add memMapOffsetLow, 8

		call .TokenTranslate

		push 2
		mov esi, memMapOffsetHigh
		add esi, 4
		mov eax, [esi]
		push eax
		push .scratch$
		call StringTokenHexadecimal

		add memMapOffsetHigh, 12
		add memMapOffsetLow, 12

		push .scratch$
		call PrintIfConfigBits32

		inc entryNumber
	mov ecx, loopIndex
	loop .MapLoop

	jmp .Exit

	.TokenTranslate:
		push 16
		mov esi, memMapOffsetHigh
		mov eax, [esi]
		push eax
		mov esi, memMapOffsetLow
		mov eax, [esi]
		push eax
		push .scratch$
		call StringTokenHexadecimalQuad
	ret


	.Exit:
	%undef loopIndex
	%undef entryNumber
	%undef memMapOffsetLow
	%undef memMapOffsetHigh
	mov esp, ebp
	pop ebp
ret

section .data
.memoryTable$									db '     Start              Length             Type', 0x00
.mapFormat$										db '^   ^   ^   ^', 0x00

section .bss
.scratch$										resb 80





section .text
MemPagesNeeded:
	; Returns the number of 4 KiB memory pages needed to hold data of the specified size
	;
	;  input:
	;	Number of bytes
	;
	;  output:
	;	EAX - Total pages which would be needed to hold the data

	push ebp
	mov ebp, esp

	; define input parameters
	%define byteSize							dword [ebp + 8]


	; pages (eax) = byteSize / 4096
	mov eax, byteSize
	shr eax, 12

	; if byteSize / 4096 doesn't fall on an even page value, add one
	mov ebx, byteSize
	and ebx, 11111111111111111111000000000000b
	cmp ebx, byteSize
	je .NoAdjust
		inc eax
	.NoAdjust:


	.Exit:
	%undef byteSize
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

	; define input parameters
	%define searchStart							dword [ebp + 8]
	%define searchLength						dword [ebp + 12]
	%define searchWord							dword [ebp + 16]


	mov esi, searchStart
	mov ecx, searchLength
	mov ebx, searchWord

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
	%undef searchStart
	%undef searchLength
	%undef searchWord
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

	; define input parameters
	%define searchStart							dword [ebp + 8]
	%define searchLength						dword [ebp + 12]
	%define searchDWord							dword [ebp + 16]


	mov esi, searchStart
	mov ecx, searchLength
	mov ebx, searchDWord

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
	%undef searchStart
	%undef searchLength
	%undef searchDWord
	mov esp, ebp
	pop ebp
ret 12





section .text
MemSearchString:
	; Searches the memory range specified for the given string
	;
	;  input:
	;	Search region start
	;	Search region length
	;	Address of string for which to search
	;
	;  output:
	;	EAX - Address of match (zero if not found)

	; this code is SUCH a kludge
	; do everyone a favor and REWRITE THIS

	push ebp
	mov ebp, esp

	; define input parameters
	%define searchStart							dword [ebp + 8]
	%define searchLength						dword [ebp + 12]
	%define stringPtr							dword [ebp + 16]


	mov esi, searchStart
	mov ecx, searchLength
	mov edi, stringPtr

	; get string length
	push edi
	call StringLength
	mov ebx, eax

	; exit if the string length is zero
	cmp eax, 0
	je .Exit

	; restore crucial stuff
	mov esi, searchStart
	mov ecx, searchLength
	mov edi, stringPtr

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
		mov edi, stringPtr
		mov esi, searchStart
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
	%undef searchStart
	%undef searchLength
	%undef stringPtr
	mov esp, ebp
	pop ebp
ret 12





section .text
MemStats:
	; Returns stats about the system's memory
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EAX - KiB total
	;	EBX - KiB free
	;	ECX - KiB used


	; calculate the initial total memory pool (adding back the first MiB which is a given)
	mov esi, [tSystem.memoryBitfieldAllocatedPtr]
	mov eax, [esi + tBitfieldInfo.elementCount]
	sub eax, [tSystem.memoryBitsInitial]
	shl eax, 2
	add eax, 0x400

	; calculate free memory
	mov ebx, [esi + tBitfieldInfo.elementCount]
	sub ebx, [esi + tBitfieldInfo.setCount]
	shl ebx, 2

	; calculate used memory
	mov ecx, eax
	sub ecx, ebx
ret





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

	; define input parameters
	%define sourcePtr							dword [ebp + 8]
	%define wordCount							dword [ebp + 12]


	mov esi, sourcePtr
	mov ecx, wordCount

	.SwapLoop:
		mov ax, [esi]
		ror ax, 8
		mov [esi], ax
		add esi, 2
	loop .SwapLoop


	.Exit:
	%undef sourcePtr
	%undef wordCount
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

	; define input parameters
	%define sourcePtr							dword [ebp + 8]
	%define dwordCount							dword [ebp + 12]


	mov esi, sourcePtr
	mov ecx, dwordCount

	.SwapLoop:
		mov eax, [esi]
		ror eax, 16
		mov [esi], eax
		add esi, 4
	loop .SwapLoop


	.Exit:
	%undef sourcePtr
	%undef dwordCount
	mov esp, ebp
	pop ebp
ret 8





; Type 1 - Usable RAM
; Type 2 - Reserved, unusable
; Type 3 - ACPI reclaimable memory
; Type 4 - ACPI NVS memory
; Type 5 - Area containing bad memory



; 64 MiB machine:
; 0000000080000: 00 00 00 00 00 00 00 00-00 fc 09 00 00 00 00 00
; 0000000080010: 01 00 00 00 00 fc 09 00-00 00 00 00 00 04 00 00
; 0000000080020: 00 00 00 00 02 00 00 00-00 00 0f 00 00 00 00 00
; 0000000080030: 00 00 01 00 00 00 00 00-02 00 00 00 00 00 10 00
; 0000000080040: 00 00 00 00 00 00 ef 03-00 00 00 00 01 00 00 00
; 0000000080050: 00 00 ff 03 00 00 00 00-00 00 01 00 00 00 00 00
; 0000000080060: 03 00 00 00 00 00 c0 fe-00 00 00 00 00 10 00 00
; 0000000080070: 00 00 00 00 02 00 00 00-00 00 e0 fe 00 00 00 00
; 0000000080080: 00 10 00 00 00 00 00 00-02 00 00 00 00 00 fc ff
; 0000000080090: 00 00 00 00 00 00 04 00-00 00 00 00 02 00 00 00
; 00000000800a0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00
; 00000000800b0: 00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00

; 0000000000000000   000000000009FC00   01
; 000000000009FC00   0000000000000400   02
; 00000000000F0000   0000000000010000   02
; 0000000000100000   0000000003EF0000   01
; 0000000003FF0000   0000000000010000   03
; 00000000FEC00000   0000000000001000   02
; 00000000FEE00000   0000000000001000   02
; 00000000FFFC0000   0000000000040000   02



; 16 GiB machine:
; 9000:00000000: 00 00 00 00 00 00 00 00-00 fc 09 00 00 00 00 00
; 9000:00000010: 01 00 00 00 00 fc 09 00-00 00 00 00 00 04 00 00
; 9000:00000020: 00 00 00 00 02 00 00 00-00 00 0f 00 00 00 00 00
; 9000:00000030: 00 00 01 00 00 00 00 00-02 00 00 00 00 00 10 00
; 9000:00000040: 00 00 00 00 00 00 ef df-00 00 00 00 01 00 00 00
; 9000:00000050: 00 00 ff df 00 00 00 00-00 00 01 00 00 00 00 00
; 9000:00000060: 03 00 00 00 00 00 c0 fe-00 00 00 00 00 10 00 00
; 9000:00000070: 00 00 00 00 02 00 00 00-00 00 e0 fe 00 00 00 00
; 9000:00000080: 00 10 00 00 00 00 00 00-02 00 00 00 00 00 fc ff
; 9000:00000090: 00 00 00 00 00 00 04 00-00 00 00 00 02 00 00 00
; 9000:000000a0: 00 00 00 00 01 00 00 00-00 00 00 20 03 00 00 00
; 9000:000000b0: 01 00 00 00

; 0000000000000000   000000000009FC00   01
; 000000000009FC00   0000000000000400   02
; 00000000000F0000   0000000000010000   02
; 0000000000100000   00000000DFEF0000   01
; 00000000DFFF0000   0000000000010000   03
; 00000000FEC00000   0000000000001000   02
; 00000000FEE00000   0000000000001000   02
; 00000000FFFC0000   0000000000040000   02
; 0000000100000000   0000000320000000   01

;					Hex						Dec
; Total bytes		00000003FFFF2000		0000017179811840
; Total KiB		 	0000000000FFFFC8		0000000016777160

; Usable bytes		00000003FFF8FC00		0000017179409408
; Usable KiB 		0000000000FFFE3F		0000000016776767
; Usable pages		00000000003FFF8F		0000000004194191

; 0x00100000 - 0x00180003 - memoryBitfieldAllocatedPtr (524292 / 0x00080004 bytes)
; 0x00180004 - 0x00200007 - memoryBitfieldReservedPtr (524292 / 0x00080004 bytes)
; 0x00200008 - 0x002000BB - BIOS memory map shadow (180 / 0xB4 bytes)
; total bytes: 1048764 / 0x001000BC
; total pages: 257 / 0x0101