; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; debug.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 32





section .text
DebugCPUFeaturesEnable:
	; Enables debugging facilities of the CPU, if supported
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; turn on the Debugging Extensions
	mov eax, cr4
	or eax, 00001000b
	mov cr4, eax

	; enable global breakpoints 1 through 4
	mov eax, 00000000000000000000000010101010b
	mov dr7, eax


	mov esp, ebp
	pop ebp
ret





section .text
DebugTraceDisable:
	; Disables the single-step feature of the CPU
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; clear the trap bit of EFLAGS
	pushf
	and dword [ebp - 4], 11111111111111111111111011111111b
	popf


	mov esp, ebp
	pop ebp
ret





section .text
DebugTraceEnable:
	; Enables the single-step feature of the CPU
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; set the trap bit of EFLAGS
	pushf
	or dword [ebp - 4], 00000000000000000000000100000000b
	popf


	mov esp, ebp
	pop ebp
ret





section .text
Debugger:
	; The kernel's built-in debugger
	;
	;  input:
	;  input:
	;	Task number of erroneous instruction	[ebp + 8]
	;	EDI register at time of trap			[ebp + 12]
	;	ESI register at time of trap			[ebp + 16]
	;	EBP register at time of trap			[ebp + 20]
	;	ESP register at time of trap			[ebp + 24]
	;	EBX register at time of trap			[ebp + 28]
	;	EDX register at time of trap			[ebp + 32]
	;	ECX register at time of trap			[ebp + 36]
	;	EAX register at time of trap			[ebp + 40]
	;	Address of return point					[ebp + 44]
	;	Selector of return point				[ebp + 48]
	;	EFlags register at time of trap			[ebp + 52]
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 12
	%define textColor							dword [ebp - 4]
	%define backColor							dword [ebp - 8]
	%define cursorY								dword [ebp - 12]


	; init values
	mov textColor, 0
	mov backColor, 2
	mov cursorY, 5


	; clear the screen to the background color if necessary
	cmp byte [.debuggerFlag], 0
	jne .SkipScreenClear
		push backColor
		call ScreenClear32
		mov byte [.debuggerFlag], 1
	.SkipScreenClear:


	; adjust the ESP we were given to its real location
	mov eax, dword [ebp + 24]
	add eax, 12
	mov dword [ebp + 24], eax


	; prep the print string
	push 80
	push .scratch$
	push .debuggerStart$
	call MemCopy


	; build the task number, selector, and address into the error string, then print
	push dword 2
	push dword [ebp + 8]
	push .scratch$
	call StringTokenHexadecimal

	push dword 4
	push dword [ebp + 48]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 44]
	push .scratch$
	call StringTokenHexadecimal

	push dword backColor
	push dword textColor
	push dword 1
	push dword 1
	push .scratch$
	call Print32


	; prep the print string
	push 80
	push .scratch$
	push .eflagsFormat$
	call MemCopy


	; print eflags
	push dword 8
	push dword [ebp + 52]
	push .scratch$
	call StringTokenHexadecimal

	push dword 32
	push dword [ebp + 52]
	push .scratch$
	call StringTokenBinary


	push dword backColor
	push dword textColor
	push dword 3
	push dword 1
	push .scratch$
	call Print32


	; print register dumps
	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EAXText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 40]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EBXText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 28]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .ECXText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 36]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EDXText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 32]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .ESIText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 16]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EDIText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 12]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EBPText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 20]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .ESPText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 24]
	call PrintRAM32

	call .CursorAdjust


	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push .EIPText$
	call Print32

	inc cursorY

	push dword backColor
	push dword textColor
	push cursorY
	push dword 1
	push dword 1
	push dword [ebp + 44]
	call PrintRAM32

	; print exit text
	push dword backColor
	push dword textColor
	mov eax, 0
	mov al, byte [kMaxLines]
	push eax
	push dword 9
	push .exitText$
	call Print32


	; get the current tasking state into BL and save it for later
	mov bl, byte [tSystem.taskingEnable]
	push ebx


	; pause tasking and turn interrupts back on so we can get keypresses again
	mov byte [tSystem.taskingEnable], 0
	sti


	; wait for a key to be pressed
	call KeyWait


	; disable interrupts again and re-enable tasking
	cli
	pop ebx
	mov byte [tSystem.taskingEnable], bl


	; see if the user decided to exit the Debugger
	cmp al, 0x76
	jne .NoExit
		; disable single step mode
		call DebugTraceDisable

		; we also need to clear the trap bit of the copy of EFLAGS we have on the stack
		mov eax, dword [ebp + 52]
		and eax, 11111111111111111111111011111111b
		mov dword [ebp + 52], eax

		; clear screen to black
		push 0x00000000
		call ScreenClear32

		; clear the flag that tells us we need to clear the screen to green next time
		mov byte [.debuggerFlag], 0
	.NoExit:


	; restore registers the way they were at entry
	mov edi, [ebp + 12]
	mov	esi, [ebp + 16]
	mov ebx, [ebp + 28]
	mov edx, [ebp + 32]
	mov ecx, [ebp + 36]
	mov eax, [ebp + 40]


	mov esp, ebp
	pop ebp
ret 36

.CursorAdjust:
	inc cursorY
	cmp byte [kMaxLines], 25
	je .CursorAdjustSkip
		; if we get here, we're using 50-line mode, so lets skip an extra line to make things prettier
		inc cursorY
	.CursorAdjustSkip:
ret

section .data
.debuggerStart$									db 'Debugger entered during task 0x^ with return point ^:^', 0x00
.eflagsFormat$									db 'Flags: 0x^ (^)', 0x00
.EAXText$										db 'Bytes at EAX:',0x00
.EBXText$										db 'Bytes at EBX:',0x00
.ECXText$										db 'Bytes at ECX:',0x00
.EDXText$										db 'Bytes at EDX:',0x00
.EBPText$										db 'Bytes at EBP:',0x00
.ESPText$										db 'Bytes at ESP:',0x00
.ESIText$										db 'Bytes at ESI:',0x00
.EDIText$										db 'Bytes at EDI:',0x00
.EIPText$										db 'Bytes at EIP:',0x00
.exitText$										db 'Press any key to single-step. Press Escape to exit the Debugger.', 0x00
.debuggerFlag									db 0x00

section .bss
.scratch$										resb 80





section .text
DebugInstacrash:
	; Causes an instant crash
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


 	; invalid opcode exception
	db 0xF0, 0xFF, 0xFF

	; GPF
	db 0xFF, 0xFF


	mov esp, ebp
	pop ebp
ret





section .text
DebugMemoryDetails:
	; Displays memory allocation
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define cursorY								dword [ebp - 4]


	; init the cursor variable
	mov cursorY, 1


	; clear the screen first
	push 0x00000000
	call ScreenClear32

	; print the description of this page and header
	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .memoryDetailsText$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
	push .memoryDetailsHeader$
	call Print32


	; set up a loop to step through all elements in the memory list for printing
	push dword [tSystem.listMemory]
	call LMElementCountGet
	mov edx, ecx

	mov cursorY, 4
	.MemoryListDumpLoop:

		; calculate what index we're on
		mov eax, edx
		sub eax, ecx

		; save the important stuff for later
		push ecx
		push edx

		; get the address of this element
		push eax
		push dword [tSystem.listMemory]
		call LMElementAddressGet

		; save esi
		push esi

		push 80
		push .scratch$
		push .memoryDetailsFormat$
		call MemCopy

		; restore and re-save esi
		pop esi
		push esi


		; build memory details string
		push dword 8
		push dword [esi + tMemInfo.address]
		push .scratch$
		call StringTokenHexadecimal

		; restore and re-save esi
		pop esi
		push esi

		push dword 8
		push dword [esi + tMemInfo.size]
		push .scratch$
		call StringTokenHexadecimal

		; restore esi
		pop esi

		push dword 2
		push dword [esi + tMemInfo.task]
		push .scratch$
		call StringTokenHexadecimal

		push dword 0x00000000
		push dword 0x00000007
		push dword cursorY
		push dword 1
		push .scratch$
		call Print32
		
		xor ebx, ebx
		mov bl, ah
		mov cursorY, ebx

		; restore the important stuff
		pop edx
		pop ecx

	loop .MemoryListDumpLoop

	; wait for escape before leaving
	call DebugWaitForEscape

	; clear the screen and exit!
	push 0x00000000
	call ScreenClear32


	mov esp, ebp
	pop ebp
ret

section .data
.memoryDetailsText$								db 'Memory Details', 0x00
.memoryDetailsHeader$							db ' Address        Size           Task (0 = unallocated, 1 = kernel)', 0x00
.memoryDetailsFormat$							db ' 0x^     0x^     0x^', 0x00

section .bss
.scratch$										resb 80





section .text
DebugMenu:
	; Implements the in-kernel debugging menu
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define cursorY								dword [ebp - 4]


	; init the cursor variable
	mov cursorY, 1


	.DrawMenu:
	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .debugMenu$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
	push .debugText1$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 4
	push dword 1
	push .debugText2$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 5
	push dword 1
	push .debugText3$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 6
	push dword 1
	push .debugText4$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 7
	push dword 1
	push .debugText5$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 8
	push dword 1
	push .debugText6$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 9
	push dword 1
	push .debugText7$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 10
	push dword 1
	push .debugText8$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 11
	push dword 1
	push .debugText9$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 12
	push dword 1
	push .debugText0$
	call Print32

	push dword 0x00000000
	push dword 0x00000007
	push dword 14
	push dword 1
	push .escMessage$
	call Print32

	.DebugLoop:
		call KeyGet

		cmp al, 0x45							; choice 0
		jne .Not0
			call Reboot
			jmp .DrawMenu
		.Not0:

		cmp al, 0x16							; choice 1
		jne .Not1
			call DebugSystemInfo
			jmp .DrawMenu
		.Not1:

		cmp al, 0x1E							; choice 2
		jne .Not2
			call DebugPCIDevices
			jmp .DrawMenu
		.Not2:

		cmp al, 0x26							; choice 3
		jne .Not3
			call DebugMemoryDetails
			jmp .DrawMenu
		.Not3:

		cmp al, 0x25							; choice 4
		jne .Not4
			call DebugRAMBrowser
			jmp .DrawMenu
		.Not4:

		cmp al, 0x2E							; choice 5
		jne .Not5
			call DebugTaskBrowser
			jmp .DrawMenu
		.Not5:

		cmp al, 0x36							; choice 6
		jne .Not6
			; put something here to jump to!
			jmp .DrawMenu
		.Not6:

		cmp al, 0x3D							; choice 7
		jne .Not7
			; put something here to jump to!
			jmp .DrawMenu
		.Not7:

		cmp al, 0x3E							; choice 8
		jne .Not8
			; put something here to jump to!
			jmp .DrawMenu
		.Not8:

		cmp al, 0x46							; choice 9
		jne .Not9
			call DebugInstacrash
			jmp .DrawMenu
		.Not9:

		hlt
	jmp .DebugLoop
	.Exit:

	mov esp, ebp
	pop ebp
ret

section .data
.debugMenu$										db 'Kernel Debug Menu', 0x00
.debugText1$									db '1 - System Info', 0x00
.debugText2$									db '2 - PCI Devices', 0x00
.debugText3$									db '3 - Memory Details', 0x00
.debugText4$									db '4 - RAM Browser', 0x00
.debugText5$									db '5 - Task Browser', 0x00
.debugText6$									db '6 - ', 0x00
.debugText7$									db '7 - ', 0x00
.debugText8$									db '8 - ', 0x00
.debugText9$									db '9 - Bandicoot', 0x00
.debugText0$									db '0 - Reboot', 0x00
.escMessage$									db 'Press Escape from any sub menu above to return to this main menu', 0x00
.debuggerMessage$								db 'What a horrible Night to have a bug.', 0x00

section .bss
.scratch$										resb 80





section .text
DebugPCIDevices:
	; Displays all PCI devices in the system
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 40
	%define cursorY								dword [ebp - 4]
	%define PCIBus								dword [ebp - 8]
	%define PCIDevice							dword [ebp - 12]
	%define PCIFunction							dword [ebp - 16]
	%define vendor								dword [ebp - 20]
	%define device								dword [ebp - 24]
	%define class								dword [ebp - 28]
	%define subclass							dword [ebp - 32]
	%define progif								dword [ebp - 36]
	%define revision							dword [ebp - 40]


	; create a new list to hold the PCI device labels if necessary
	cmp byte [.flag], 1
	je .PCIInitSkip

		; if we get here, this hasn't been set up yet... so let's do so!

		; the list will be 256 entries of 36 bytes each
		; allocate memory for the list
		push 256 * 36 + 16
		push dword 1
		call MemAllocate

		; see if there was an error, if not save the pointer
		cmp edx, kErrNone
		jne .Exit

		mov [PCIDeviceInfo.PCIClassTable], eax

		; set up the list header
		push 36
		push 256
		push eax
		call LMListInit


		; write all the strings to the list area
		push dword 20
		push PCIDeviceInfo.PCI00$
		push dword 0
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 24
		push PCIDeviceInfo.PCI01$
		push dword 1
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 19
		push PCIDeviceInfo.PCI02$
		push dword 2
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 19
		push PCIDeviceInfo.PCI03$
		push dword 3
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 22
		push PCIDeviceInfo.PCI04$
		push dword 4
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 18
		push PCIDeviceInfo.PCI05$
		push dword 5
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 14
		push PCIDeviceInfo.PCI06$
		push dword 6
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 32
		push PCIDeviceInfo.PCI07$
		push dword 7
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 26
		push PCIDeviceInfo.PCI08$
		push dword 8
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 13
		push PCIDeviceInfo.PCI09$
		push dword 9
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 16
		push PCIDeviceInfo.PCI0A$
		push dword 10
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 10
		push PCIDeviceInfo.PCI0B$
		push dword 11
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 15
		push PCIDeviceInfo.PCI0C$
		push dword 12
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 20
		push PCIDeviceInfo.PCI0D$
		push dword 13
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 27
		push PCIDeviceInfo.PCI0E$
		push dword 14
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 36
		push PCIDeviceInfo.PCI0F$
		push dword 15
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 22
		push PCIDeviceInfo.PCI10$
		push dword 16
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 29
		push PCIDeviceInfo.PCI11$
		push dword 17
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 23
		push PCIDeviceInfo.PCI12$
		push dword 18
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 30
		push PCIDeviceInfo.PCI13$
		push dword 19
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 12
		push PCIDeviceInfo.PCI40$
		push dword 64
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot

		push dword 17
		push PCIDeviceInfo.PCIFF$
		push dword 255
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		mov byte [.flag], 1

	.PCIInitSkip:
	push 0x00000000
	call ScreenClear32

	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .PCIInfoText$
	call Print32

	; print the device description header
	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
	push .PCIDeviceDescriptionText1$
	call Print32


	; init the values
	mov PCIBus, 0xFFFFFFFF
	mov PCIDevice, 0xFFFFFFFF
	mov PCIFunction, 0xFFFFFFFF

	mov cursorY, 4
	.PCIListAllLoop:
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIFunctionNextGet
		mov PCIBus, eax
		mov PCIDevice, ebx
		mov PCIFunction, ecx

		; see if we're done yet
		mov eax, PCIBus
		add eax, PCIDevice
		add eax, PCIFunction
		cmp eax, 0x0002FFFD
		je .End

		; get info on the device
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoVendorGet
		mov vendor, eax

		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoDeviceGet
		mov device, eax

		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoClassGet
		mov class, eax

		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoSubclassGet
		mov subclass, eax

		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoProgIfGet
		mov progif, eax

		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIInfoRevisionGet
		mov revision, eax


		; first calculate the address of the string which describes this device
		push class
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMElementAddressGet

		; save the address for later
		push esi

		; build the rest of the PCI data into line 1 for this device
		push 80
		push .scratch$
		push .format$
		call MemCopy

		push dword 2
		push PCIBus
		push .scratch$
		call StringTokenHexadecimal

		push dword 2
		push PCIDevice
		push .scratch$
		call StringTokenHexadecimal

		push dword 1
		push PCIFunction
		push .scratch$
		call StringTokenHexadecimal

		push dword 4
		push vendor
		push .scratch$
		call StringTokenHexadecimal

		push dword 4
		push device
		push .scratch$
		call StringTokenHexadecimal

		push dword 2
		push class
		push .scratch$
		call StringTokenHexadecimal

		push dword 2
		push subclass
		push .scratch$
		call StringTokenHexadecimal

		push dword 2
		push progif
		push .scratch$
		call StringTokenHexadecimal

		push dword 2
		push revision
		push .scratch$
		call StringTokenHexadecimal

		pop eax
		push dword 0
		push eax
		push .scratch$
		call StringTokenString

		; print the string we just built
		push dword 0x00000000
		push dword 0x00000007
		push cursorY
		push dword 1
		push .scratch$
		call Print32
		xor ebx, ebx
		mov bl, ah
		mov cursorY, ebx

	jmp .PCIListAllLoop


	.End:
	call DebugWaitForEscape

	; clear the screen and exit
	push 0x00000000
	call ScreenClear32

	.Exit:
	mov esp, ebp
	pop ebp
ret

section .bss
.scratch$										resb 80

section .data
.flag											db 0x00
.PCIInfoText$									db 'PCI Devices', 0x00
.PCIDeviceDescriptionText1$						db 'Bus Dev  Fn  Vend  Dev   Cl  Sc  PI  Rv  Description', 0x00
.format$										db '^  ^   ^   ^  ^  ^  ^  ^  ^  ^', 0x00

; struct to hold all data about a single PCI device for the system menu
PCIDeviceInfo:
.PCIClassTable									dd 0x00000000
.PCI00$											db 'Unclassified device', 0x00
.PCI01$											db 'Mass Storage Controller', 0x00
.PCI02$											db 'Network Controller', 0x00
.PCI03$											db 'Display Controller', 0x00
.PCI04$											db 'Multimedia Controller', 0x00
.PCI05$											db 'Memory Controller', 0x00
.PCI06$											db 'Bridge Device', 0x00
.PCI07$											db 'Simple Communication Controller', 0x00
.PCI08$											db 'Generic System Peripheral', 0x00
.PCI09$											db 'Input Device', 0x00
.PCI0A$											db 'Docking Station', 0x00
.PCI0B$											db 'Processor', 0x00
.PCI0C$											db 'USB Controller', 0x00
.PCI0D$											db 'Wireless Controller', 0x00
.PCI0E$											db 'Intelligent I/O Controller', 0x00
.PCI0F$											db 'Satellite Communications Controller', 0x00
.PCI10$											db 'Encryption Controller', 0x00
.PCI11$											db 'Signal Processing Controller', 0x00
.PCI12$											db 'Processing Accelerator', 0x00
.PCI13$											db 'Non-Essential Instrumentation', 0x00
.PCI40$											db 'Coprocessor', 0x00
.PCIFF$											db 'Unassigned class', 0x00





section .text
DebugRAMBrowser:
	; An interactive memory broswer
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 12
	%define numLines							dword [ebp - 4]
	%define scrollAmount						dword [ebp - 8]
	%define superScrollAmount					dword [ebp - 12]


	; clear the screen first
	push 0x00000000
	call ScreenClear32

	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .RAMBrowserText$
	call Print32


	; set the default values
	mov numLines, 32
	mov scrollAmount, 0x200
	mov superScrollAmount, 0x200000


	; adjust defaults if using the 25-line screen mode
	cmp byte [kMaxLines], 25
	jne .displayLoop

		; if we get here, we're using the 25-line screen mode, so we adjust numLines
		mov numLines, 16
		mov scrollAmount, 0x100
		mov superScrollAmount, 0x100000

	.displayLoop:
		; dump some RAM!
		push dword 0x00000000
		push dword 0x00000007
		push dword 3
		push dword 1
		push numLines
		push dword [.startAddress]
		call PrintRAM32


		; show the jump address string
		mov eax, numLines
		add eax, 4
		push dword 0x00000000
		push dword 0x00000007
		push eax
		push dword 13
		push .JumpText$
		call Print32

		mov eax, numLines
		add eax, 5
		push dword 0x00000000
		push dword 0x00000007
		push eax
		push dword 37
		push .JumpString$
		call Print32


		; get a keypress and handle it
		call KeyGet

		cmp al, 0x45							; 0
		jne .Not0
			push dword 48
			jmp .HandleHexDigit
		.Not0:

		cmp al, 0x16							; 1
		jne .Not1
			push dword 49
			jmp .HandleHexDigit
		.Not1:

		cmp al, 0x1E							; 2
		jne .Not2
			push dword 50
			jmp .HandleHexDigit
		.Not2:

		cmp al, 0x26							; 3
		jne .Not3
			push dword 51
			jmp .HandleHexDigit
		.Not3:

		cmp al, 0x25							; 4
		jne .Not4
			push dword 52
			jmp .HandleHexDigit
		.Not4:

		cmp al, 0x2E							; 5
		jne .Not5
			push dword 53
			jmp .HandleHexDigit
		.Not5:

		cmp al, 0x36							; 6
		jne .Not6
			push dword 54
			jmp .HandleHexDigit
		.Not6:

		cmp al, 0x3D							; 7
		jne .Not7
			push dword 55
			jmp .HandleHexDigit
		.Not7:

		cmp al, 0x3E							; 8
		jne .Not8
			push dword 56
			jmp .HandleHexDigit
		.Not8:

		cmp al, 0x46							; 9
		jne .Not9
			push dword 57
			jmp .HandleHexDigit
		.Not9:

		cmp al, 0x1C							; A
		jne .NotA
			push dword 65
			jmp .HandleHexDigit
		.NotA:

		cmp al, 0x32							; B
		jne .NotB
			push dword 66
			jmp .HandleHexDigit
		.NotB:

		cmp al, 0x21							; C
		jne .NotC
			push dword 67
			jmp .HandleHexDigit
		.NotC:

		cmp al, 0x23							; D
		jne .NotD
			push dword 68
			jmp .HandleHexDigit
		.NotD:

		cmp al, 0x24							; E
		jne .NotE
			push dword 69
			jmp .HandleHexDigit
		.NotE:

		cmp al, 0x2B							; F
		jne .NotF
			push dword 70
			jmp .HandleHexDigit
		.NotF:

		cmp al, 0x5A							; Enter
		jne .NotEnter
			push .JumpString$
			call ConvertStringHexToNumber
			mov dword [.startAddress], eax
		.NotEnter:
	
		cmp al, 0x7B							; -
		jne .NotMinus
			mov eax, scrollAmount
			sub dword [.startAddress], eax
		.NotMinus:
		
		cmp al, 0x79							; +
		jne .NotPlus
			mov eax, scrollAmount
			add dword [.startAddress], eax
		.NotPlus:
		
		cmp al, 0x7D							; Page Up
		jne .NotPageUp
			mov eax, superScrollAmount
			sub dword [.startAddress], eax
		.NotPageUp:
		
		cmp al, 0x7A							; Page Down
		jne .NotPageDown
			mov eax, superScrollAmount
			add dword [.startAddress], eax
		.NotPageDown:
		
		cmp al, 0x76							; Escape
		jne .NotEsc
			jmp .DisplayLoopDone
		.NotEsc:

	jmp .displayLoop

	.DisplayLoopDone:

	; clear the screen and exit!
	push 0x00000000
	call ScreenClear32


	mov esp, ebp
	pop ebp
ret

.HandleHexDigit:
	push .JumpString$
	call StringCharAppend

	push dword 8
	push .JumpString$
	call StringTruncateLeft
jmp .displayLoop

section .data
.startAddress									dd 0x00000000
.RAMBrowserText$								db 'RAM Browser', 0x00
.JumpText$										db 'Type a hex value and press Enter to jump to that address', 0x00, 0x00
.JumpString$									db '00000000', 0x00, 0x00





section .text
DebugStackTrace:
	; Traces the stack and prints a list of return addresses
	;
	;  input:
	;	Stack address (ESP)
	;	X position
	;	Y position
	;	Text color
	;	Back color
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; set the starting point of our trace
	mov eax, dword [ebp + 8]
	mov ebx, [eax]

	.TraceLoop:
		; see if we're done
		cmp ebx, 0
		je .done

		; prep the print string
		push 80
		push .scratch$
		push .traceFormat$
		call MemCopy


		; load the previous stack frame's eip into edx
		mov edx, [ebx + 4]							


		; load the previous stack frame's ebp into ebx
		mov ebx, [ebx + 0]							


		pusha


		; print the address we found
		push dword 32
		push edx
		push .scratch$
		call StringTokenHexadecimal


		; print the string we just built
		mov eax, 0x00000000

		push dword [ebp + 24]
		push dword [ebp + 20]
		push dword [ebp + 16]
		push dword [ebp + 12]
		push .scratch$
		call Print32

		popa
	jmp	.TraceLoop

	.done:
	mov esp, ebp
	pop ebp
ret 20

section .data
.traceFormat$									db ' ^', 0x00

section .bss
.scratch$										resb 80





section .text
DebugSystemInfo:
	; Displays information about the system on which Night is running
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; clear the screen first
	push 0x00000000
	call ScreenClear32

	; print the description of this page
	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .systemInfoText$
	call Print32


	; print the kernel string
	push dword 0x00000000
	push dword 0x00000007
	push dword 5
	push dword 1
	push tSystem.copyright$
	call Print32


	; build and print the version string
	push 80
	push .scratch$
	push .versionFormat$
	call MemCopy

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.versionMajor]
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.versionMinor]
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 0
	mov eax, 0x00000000
	mov ax, word [tSystem.versionBuild]
	push eax
	push .scratch$
	call StringTokenDecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 7
	push dword 1
	push .scratch$
	call Print32


	; print the CPU string
	push dword 0x00000000
	push dword 0x00000007
	push dword 9
	push dword 1
	push tSystem.CPUIDBrand$
	call Print32


	; build and print the Drive List string
	push 80
	push .scratch$
	push .listDriveFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listDrives]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 11
	push dword 1
	push .scratch$
	call Print32


	; build and print the DriveLetters List string
	push 80
	push .scratch$
	push .listDriveLettersFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listDriveLetters]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 13
	push dword 1
	push .scratch$
	call Print32


	; build and print the FS Handlers List string
	push 80
	push .scratch$
	push .listFSHandlersFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listFSHandlers]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 15
	push dword 1
	push .scratch$
	call Print32


	; build and print the Memory List string
	push 80
	push .scratch$
	push .listMemoryFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listMemory]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 17
	push dword 1
	push .scratch$
	call Print32


	; build and print the Partition List string
	push 80
	push .scratch$
	push .listPartitionFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listPartitions]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 19
	push dword 1
	push .scratch$
	call Print32


	; build the Tasks List string
	push 80
	push .scratch$
	push .listTasksFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listTasks]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 21
	push dword 1
	push .scratch$
	call Print32


	; ESC lets us leave, kids
	call DebugWaitForEscape

	; clear the screen and exit!
	push 0x00000000
	call ScreenClear32


	mov esp, ebp
	pop ebp
ret

section .data
.systemInfoText$								db 'System Information', 0x00
.versionFormat$									db 'Kernel version ^.^ build ^', 0x00
.listDriveFormat$								db 'Drive List             0x^', 0x00
.listDriveLettersFormat$						db 'Drive Letters List     0x^', 0x00
.listFSHandlersFormat$							db 'FS Handlers List       0x^', 0x00
.listPartitionFormat$							db 'Partition List         0x^', 0x00
.listPCIDevicesFormat$							db 'PCI Devices List       0x^', 0x00
.listTasksFormat$								db 'Tasks List             0x^', 0x00
.listMemoryFormat$								db 'Memory List            0x^', 0x00

section .bss
.scratch$										resb 80





section .text
DebugTaskBrowser:
	; Browse information on all loaded tasks
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 5
	%define currentTaskSlotAddress				dword [ebp - 4]
	%define currentTask							byte [ebp - 5]


	; init variables
	mov currentTaskSlotAddress, 0
	mov currentTask, 0

	.PrintTaskInfo:
	push 0x00000000
	call ScreenClear32

	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .IntroText$
	call Print32


	; print the instructions
	push dword 0x00000000
	push dword 0x00000007
	push dword 25
	push dword 1
	push .Instructions$
	call Print32


	; get the starting address of this task's slot in the task list
	mov eax, 0x00000000
	mov al, currentTask
	push eax
	push dword [tSystem.listTasks]
	call LMElementAddressGet
	mov currentTaskSlotAddress, esi


	push 80
	push .scratch$
	push .taskNumberFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 2
	mov eax, 0x00000000
	mov al, currentTask
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 5
	push dword 1
	push .scratch$
	call Print32


	; print the task's name (if not null)
	; load the task's slot into eax, then adjust it to point to the name field
	mov eax, currentTaskSlotAddress
	add eax, 64
	cmp byte [eax], 0
	je .SkipName
		push dword 0x00000000
		push dword 0x00000007
		push dword 5
		push dword 33
		push eax
		call Print32
	.SkipName:


	push 80
	push .scratch$
	push .spawnedByFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 2
	push dword [esi + tTaskInfo.spawnedBy]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 7
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .taskSlotAddress$
	call MemCopy

	push dword 8
	push currentTaskSlotAddress
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 9
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .entryPointFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 8
	push dword [esi + tTaskInfo.entryPoint]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 11
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .kernelStackAddressFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 8
	push dword [esi + tTaskInfo.kernelStackAddress]
	push .scratch$
	call StringTokenHexadecimal

	mov esi, currentTaskSlotAddress
	push dword 8
	mov eax, dword [esi + tTaskInfo.kernelStackAddress]
	add eax, dword [tSystem.taskKernelStackSize]
	dec eax
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 13
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .stackAddressFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 8
	push dword [esi + tTaskInfo.stackAddress]
	push .scratch$
	call StringTokenHexadecimal

	mov esi, currentTaskSlotAddress
	push dword 8
	mov eax, dword [esi + tTaskInfo.stackAddress]
	add eax, dword [tSystem.taskStackSize]
	dec eax
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 15
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .priorityFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 2
	push dword [esi + tTaskInfo.priority]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 17
	push dword 1
	push .scratch$
	call Print32


	push 80
	push .scratch$
	push .taskFlagsFormat$
	call MemCopy

	mov esi, currentTaskSlotAddress
	push dword 8
	push dword [esi + tTaskInfo.taskFlags]
	push .scratch$
	call StringTokenBinary

	push dword 0x00000000
	push dword 0x00000007
	push dword 19
	push dword 1
	push .scratch$
	call Print32


	.GetInputLoop:
		; display timeslice usage, since this should be updated live
		push 80
		push .scratch$
		push .CPULoadFormat$
		call MemCopy

		mov esi, currentTaskSlotAddress
		push dword 10
		push dword [esi + tTaskInfo.cycleCountHigh]
		push .scratch$
		call StringTokenDecimal

		mov esi, currentTaskSlotAddress
		push dword 10
		push dword [esi + tTaskInfo.cycleCountLow]
		push .scratch$
		call StringTokenDecimal

		push dword 0x00000000
		push dword 0x00000007
		push dword 21
		push dword 1
		push .scratch$
		call Print32


		; now get and handle input
		call KeyGet

		; see what was pressed
		cmp al, 0x7D							; Page Up
		jne .NotPageUp
			dec currentTask
			jmp .PrintTaskInfo
		.NotPageUp:

		cmp al, 0x7A							; Page Down
		jne .NotPageDown
			inc currentTask
			jmp .PrintTaskInfo
		.NotPageDown:

		cmp al, 0x76							; Escape
		jne .NotEscape
			jmp .End
		.NotEscape:

		cmp al, 0x29							; Spacebar
		jne .NotSpacebar
			mov esi, currentTaskSlotAddress
			mov al, byte [esi + tTaskInfo.taskFlags]
			btc ax, 1
			mov byte [esi + tTaskInfo.taskFlags], al
			jmp .PrintTaskInfo
		.NotSpacebar:

		cmp al, 0x5A							; Enter
		jne .NotEnter
			mov eax, 0x00000000
			mov al, currentTask
			push eax
			call TaskKill
			jmp .PrintTaskInfo
		.NotEnter:

		cmp al, 0x7B							; -
		jne .NotMinus
			mov esi, currentTaskSlotAddress
			dec byte [esi + tTaskInfo.priority]
			jmp .PrintTaskInfo
		.NotMinus:
		
		cmp al, 0x79							; +
		jne .NotPlus
			mov esi, currentTaskSlotAddress
			inc byte [esi + tTaskInfo.priority]
			jmp .PrintTaskInfo
		.NotPlus:

	jmp .GetInputLoop


	.End:
	; clear the screen and exit
	push 0x00000000
	call ScreenClear32


	mov esp, ebp
	pop ebp
ret

section .bss
.scratch$										resb 80

section .data
.IntroText$										db 'Task Browser', 0x00
.Instructions$									db 'Browse: Pg Up/Pg Dn, Suspend: Spacebar, Kill: Enter, Adjust priority: +/-', 0x00
.taskNumberFormat$								db 'Task number                0x^', 0x00
.spawnedByFormat$								db 'Spawned by                 0x^', 0x00
.taskSlotAddress$								db 'Task list slot address     0x^', 0x00
.entryPointFormat$								db 'Entry point                0x^', 0x00
.kernelStackAddressFormat$						db 'Kernel stack area          0x^ - 0x^', 0x00
.stackAddressFormat$							db 'Task stack area            0x^ - 0x^', 0x00
.priorityFormat$								db 'Priority                   0x^', 0x00
.taskFlagsFormat$								db 'Flags                      0x^', 0x00
.CPULoadFormat$									db 'Timeslice utilization      ^ ^', 0x00
.pageDirAddressFormat$							db 'Page directory address     0x^', 0x00





section .text
DebugVBoxLogWrite:
	; Writes the string specidfied to the VirtualBox guest log
	;
	;  input:
	;	String address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get the address of the string
	mov esi, [ebp + 8]
	
	; get the string's length
	push esi
	call StringLength
	mov ecx, eax

	; save the length for later
	mov ebx, ecx
	
	; write to the log
	mov dx, 0x0504
	rep outsb

	; VirtualBox seems to buffer all output to the log and only flush on every 512th byte, as long as it's not null
	; we allow for this behaviour here
	mov ecx, 511
	sub ecx, ebx
	.logWriteLoop:
		mov dx, 0x504
		mov al, 0
		out dx, al
	loop .logWriteLoop


	mov esp, ebp
	pop ebp
ret 4





section .text
DebugWaitForEscape:
	; Waits for the Escape key to be pressed, then returns
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	.KeyLoop:

		; get a key
		call KeyWait

		; see if it was Escape
		cmp al, 0x76

	jne .KeyLoop


	mov esp, ebp
	pop ebp
ret
