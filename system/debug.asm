; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; debug.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 32-bit function listing:
; DebugMenu						Implements the in-kernel debugging menu
; DebugVBOXLogWrite				Writes a string specidfied to the VirtualBOX guest log
; StackTrace					Traces the stack and prints a list of return addresses





bits 32





section .text
DebugMenu:
	; Implements the in-kernel debugging menu
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; create a new list to hold the PCI device labels if necessary
	cmp byte [.flag], 1
	je .DrawMenu

		; if we get here, this hasn't been set up yet... so let's do so!

		; the list will be 256 entries of 36 bytes each
		; 256 * 36 + 16 = 9232 (0x2410)
		; allocate memory for the list
		push 9232
		push dword 1
		call MemAllocate
		pop edi

		mov [PCITable.PCIClassTable], edi

		; set up the list header
		push 36
		push 256
		push edi
		call LMListInit


		; write all the strings to the list area
		push dword 20
		push PCITable.PCI00$
		push dword 0
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 24
		push PCITable.PCI01$
		push dword 1
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 19
		push PCITable.PCI02$
		push dword 2
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 19
		push PCITable.PCI03$
		push dword 3
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 22
		push PCITable.PCI04$
		push dword 4
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 18
		push PCITable.PCI05$
		push dword 5
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 14
		push PCITable.PCI06$
		push dword 6
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 32
		push PCITable.PCI07$
		push dword 7
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 26
		push PCITable.PCI08$
		push dword 8
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 13
		push PCITable.PCI09$
		push dword 9
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 16
		push PCITable.PCI0A$
		push dword 10
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 10
		push PCITable.PCI0B$
		push dword 11
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 15
		push PCITable.PCI0C$
		push dword 12
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 20
		push PCITable.PCI0D$
		push dword 13
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 27
		push PCITable.PCI0E$
		push dword 14
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 36
		push PCITable.PCI0F$
		push dword 15
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 22
		push PCITable.PCI10$
		push dword 16
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 29
		push PCITable.PCI11$
		push dword 17
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 23
		push PCITable.PCI12$
		push dword 18
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 30
		push PCITable.PCI13$
		push dword 19
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 12
		push PCITable.PCI40$
		push dword 64
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 17
		push PCITable.PCIFF$
		push dword 255
		push dword [PCITable.PCIClassTable]
		call LMItemAddAtSlot
		pop eax
		mov byte [.flag], 1

	.DrawMenu:
	mov byte [textColor], 7
	mov byte [backColor], 0

	mov byte [cursorX], 1
	mov byte [cursorY], 1
	push .debugMenu$
	call Print32

	mov byte [cursorY], 3
	push .debugText1$
	call Print32

	push .debugText2$
	call Print32

	push .debugText3$
	call Print32

	push .debugText4$
	call Print32

	push .debugText5$
	call Print32

	push .debugText6$
	call Print32

	push .debugText7$
	call Print32

	push .debugText8$
	call Print32

	push .debugText9$
	call Print32

	push .debugText0$
	call Print32

	inc byte [cursorY]
	push .escMessage$
	call Print32

	.DebugLoop:
		push 0
		call KeyGet



		mov byte [cursorY], 17


		; clear our print string
		push dword 0
		push dword 256
		push kPrintText$
		call MemFill

		; do the ticks/seconds since boot string
		push dword [tSystem.ticksSinceBoot]

		push kPrintText$
		push .ticksFormat$
		call StringBuild

		push kPrintText$
		call Print32

		; clear our print string
		push dword 0
		push dword 256
		push kPrintText$
		call MemFill

		; do the date and time info string
		mov eax, 0x00000000
		mov al, byte [tSystem.year]
		push eax

		mov eax, 0x00000000
		mov al, byte [tSystem.day]
		push eax

		mov eax, 0x00000000
		mov al, byte [tSystem.month]
		push eax

		mov eax, 0x00000000
		mov al, byte [tSystem.seconds]
		push eax

		mov eax, 0x00000000
		mov al, byte [tSystem.minutes]
		push eax

		mov eax, 0x00000000
		mov al, byte [tSystem.hours]
		push eax

		push kPrintText$
		push .dateTimeFormat$
		call StringBuild

		push kPrintText$
		call Print32


		; show mouse location and buttons
		mov eax, 0
		mov al, byte [tSystem.mouseButtons]
		push eax

		mov eax, 0
		mov ax, word [tSystem.mouseZ]
		push eax

		mov eax, 0
		mov ax, word [tSystem.mouseY]
		push eax

		mov eax, 0
		mov ax, word [tSystem.mouseX]
		push eax

		push kPrintText$
		push .mouseFormat$
		call StringBuild

		mov byte [cursorY], 22
		push kPrintText$
		call Print32


		pop eax

		cmp al, 0x45							; choice 0
		jne .TestFor1
		call Reboot
		jmp .DrawMenu

		.TestFor1:
		cmp al, 0x16							; choice 1
		jne .TestFor2
		call .SystemInfo
		jmp .DrawMenu

		.TestFor2:
		cmp al, 0x1E							; choice 2
		jne .TestFor3
		call .PCIDevices
		jmp .DrawMenu

		.TestFor3:
		cmp al, 0x26							; choice 3
		jne .TestFor4
		call .MemoryDetails
		jmp .DrawMenu

		.TestFor4:
		cmp al, 0x25							; choice 4
		jne .TestFor5
		call .Exit
		jmp .DrawMenu

		.TestFor5:
		cmp al, 0x2E							; choice 5
		jne .TestFor6
		call .Exit
		jmp .DrawMenu

		.TestFor6:
		cmp al, 0x36							; choice 6
		jne .TestFor7
		jmp .Exit
		jmp .DrawMenu

		.TestFor7:
		cmp al, 0x3D							; choice 7
		jne .TestFor8
		jmp .Exit
		jmp .DrawMenu

		.TestFor8:
		cmp al, 0x3E							; choice 8
		jne .TestFor9
		jmp .Exit
		jmp .DrawMenu

		.TestFor9:
		cmp al, 0x46							; choice 9
		jne .DebugLoop
		jmp .Exit
		jmp .DrawMenu

	jmp .DebugLoop
	.Exit:

	mov esp, ebp
	pop ebp
ret

section .data
.flag											db 0x00
.debugMenu$										db 'Kernel Debug Menu', 0x00
.debugText1$									db '1 - System Info', 0x00
.debugText2$									db '2 - PCI Devices', 0x00
.debugText3$									db '3 - Memory Details', 0x00
.debugText4$									db '4 - ', 0x00
.debugText5$									db '5 - ', 0x00
.debugText6$									db '6 - ', 0x00
.debugText7$									db '7 - ', 0x00
.debugText8$									db '8 - ', 0x00
.debugText9$									db '9 - ', 0x00
.debugText0$									db '0 - Reboot', 0x00
.escMessage$									db 'Press Escape from any sub menu above to return to this main menu', 0x00
.ticksFormat$									db 'Ticks since boot: ^p10^d', 0x00
.dateTimeFormat$								db '^p2^d:^d:^d     ^p2^d/^d/^d', 0x00
.mouseFormat$									db 'X: ^p4^d     Y: ^d     Z: ^d     Buttons: ^p8^b     ', 0x00



section .text
.MemoryDetails:
	; clear the screen first
	call ScreenClear32

	; print the description of this page and header
	mov byte [textColor], 7
	mov byte [backColor], 0
	push .memoryDetailsText$
	call Print32

	inc byte [cursorY]
	mov byte [textColor], 7
	mov byte [backColor], 0
	push .memoryDetailsHeader$
	call Print32

	; set up a loop to step through all elements in the memory list for printing
	push dword 0
	push dword [tSystem.listMemory]
	call LMElementCountGet
	pop ecx
	pop edx
	mov edx, ecx

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
		pop esi
		; ignore error code
		pop ecx

		; print the data
		push dword [tMemInfo.task]
		push dword [tMemInfo.size]
		push dword [tMemInfo.address]
		push kPrintText$
		push .memoryDetailsFormat$
		call StringBuild

		push kPrintText$
		call Print32

		; restore the important stuff
		pop edx
		pop ecx

	loop .MemoryListDumpLoop

	; wait for escape before leaving
	call .WaitForEscape

	; clear the screen and exit!
	call ScreenClear32
ret

section .data
.memoryDetailsText$								db 'Memory Details', 0x00
.memoryDetailsHeader$							db ' Address        Size           Task (0 = unallocated, 1 = kernel)', 0x00
.memoryDetailsFormat$							db '^p8 0x^h     0x^h^p2     0x^h', 0x00



section .text
.SystemInfo:
	; clear the screen first
	call ScreenClear32

	; print the description of this page
	mov byte [textColor], 7
	mov byte [backColor], 0
	push .systemInfoText$
	call Print32

	; print the kernel string
	mov byte [cursorY], 5
	push tSystem.copyright$
	call Print32

	; build the version string
	mov eax, 0x00000000
	mov al, byte [tSystem.versionMinor]
	push eax

	mov al, byte [tSystem.versionMajor]
	push eax
	
	push kPrintText$
	push .versionFormat$
	call StringBuild

	; print the version string
	inc byte [cursorY]
	push kPrintText$
	call Print32

	; print the CPU string
	inc byte [cursorY]
	push tSystem.CPUIDBrand$
	call Print32

	; build the drive list string
	mov eax, [tSystem.listDrives]
	push eax
	push kPrintText$
	push .listDriveFormat$
	call StringBuild

	; print the drive list string
	inc byte [cursorY]
	push kPrintText$
	call Print32


	; build the memory list string
	mov eax, [tSystem.listMemory]
	push eax
	push kPrintText$
	push .listMemoryFormat$
	call StringBuild

	; print the memory list string
	inc byte [cursorY]
	push kPrintText$
	call Print32


	; build the partition list string
	mov eax, [tSystem.listPartitions]
	push eax
	push kPrintText$
	push .listPartitionFormat$
	call StringBuild

	; print the drive list string
	inc byte [cursorY]
	push kPrintText$
	call Print32


	; build the PCI devices List string
	mov eax, [tSystem.listPCIDevices]
	push eax
	push kPrintText$
	push .listPCIDevicesFormat$
	call StringBuild

	; print the drive list string
	inc byte [cursorY]
	push kPrintText$
	call Print32


	; build the PCI devices List string
	mov eax, [tSystem.listTasks]
	push eax
	push kPrintText$
	push .listTasksFormat$
	call StringBuild

	; print the drive list string
	inc byte [cursorY]
	push kPrintText$
	call Print32

	; ESC lets us leave, kids
	call .WaitForEscape

	; clear the screen and exit!
	call ScreenClear32
ret

section .data
.systemInfoText$								db 'System Information', 0x00
.versionFormat$									db 'Kernel version ^p2^h.^h', 0x00
.listDriveFormat$								db 'Drive List                0x^p8^h', 0x00
.listPartitionFormat$							db 'Partition List            0x^p8^h', 0x00
.listPCIDevicesFormat$							db 'PCI Devices List          0x^p8^h', 0x00
.listTasksFormat$								db 'Tasks List                0x^p8^h', 0x00
.listMemoryFormat$								db 'Memory List               0x^p8^h', 0x00



section .text
.PCIDevices:
	call ScreenClear32

	mov byte [textColor], 7
	mov byte [backColor], 0
	push .PCIInfoText$
	call Print32

	; see if we have to print data on all devices of on a specific device
	cmp dword [.currentDevice], 0
	jne .PrintSpecificDevice
	
		; if we get here, the index is 0 so we print all devices
	
		; build and print the device count string
		push dword [tSystem.PCIDeviceCount]
		push kPrintText$
		push .PCIDeviceCountText$
		call StringBuild
	
		push kPrintText$
		call Print32

		; print the device description header
		inc byte [cursorY]
		push .PCIDeviceDescriptionText1$
		call Print32

		; init the values
		mov dword [.PCIBus], 0
		mov dword [.PCIDevice], 0
		mov dword [.PCIFunction], 0

		.PCIListAllLoop:
			push dword [.PCIFunction]
			push dword [.PCIDevice]
			push dword [.PCIBus]
			call PCIGetNextFunction
			pop dword [.PCIFunction]
			pop dword [.PCIDevice]
			pop dword [.PCIBus]

			; see if we're done yet
			mov eax, dword [.PCIBus]
			add eax, dword [.PCIDevice]
			add eax, dword [.PCIFunction]
			cmp eax, 0x0002FFFD
			je .GetInputLoop

			; get info on the first device
			push PCIDeviceInfo
			push dword [.PCIFunction]
			push dword [.PCIDevice]
			push dword [.PCIBus]
			call PCIReadAll

			; first calculate the address of the string which describes this device
			mov eax, 0x00000000
			mov al, byte [PCIDeviceInfo.PCIClass]
			push eax
			push dword [PCITable.PCIClassTable]
			call LMElementAddressGet
			pop edx
			; ignore error code
			pop ecx

			; save the address for later
			push edx

			; build the rest of the PCI data into line 1 for this device
			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIRevision]
			push eax

			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIProgIf]
			push eax

			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCISubclass]
			push eax

			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIClass]
			push eax

			mov eax, 0x00000000
			mov ax, [PCIDeviceInfo.PCIDeviceID]
			push eax

			mov eax, 0x00000000
			mov ax, [PCIDeviceInfo.PCIVendorID]
			push eax
			push dword [.PCIFunction]
			push dword [.PCIDevice]
			push dword [.PCIBus]
			push kPrintText$
			push .format$
			call StringBuild

			; print the string we just built
			push kPrintText$
			call Print32

			; advance to the next slot
			push dword [.PCIFunction]
			push dword [.PCIDevice]
			push dword [.PCIBus]
			call PCICalculateNext
			pop dword [.PCIFunction]
			pop dword [.PCIDevice]
			pop dword [.PCIBus]

		jmp .PCIListAllLoop

	.PrintSpecificDevice:
	; here we print info for just one specific device
	; we start by building and printing the device count string
	push dword [tSystem.PCIDeviceCount]
	push dword [.currentDevice]
	push kPrintText$
	push .PCIDeviceListingText$
	call StringBuild

	push kPrintText$
	call Print32

	mov eax, dword [.currentDevice]
	dec eax
	push eax
	push dword [tSystem.listPCIDevices]
	call LMElementAddressGet
	pop eax
	; ignore error code
	pop ecx


	; adjust the address to skip the pci bus/device/function data
	add eax, 12

	; dump the memory space
	inc byte [cursorY]		
	push dword 16
	push eax
	call PrintRAM32
			
	.GetInputLoop:
		push 0
		call KeyWait
		pop eax

		; see what was pressed
		cmp eax, 0x7D
		je .PageUp
	
		cmp eax, 0x7A
		je .PageDown
	
		cmp eax, 0x76
		je .End

	jmp .GetInputLoop

	.PageUp:
		dec dword [.currentDevice]
		cmp dword [.currentDevice], 0xFFFFFFFF
		jne .PCIDevices
		inc dword [.currentDevice]
	jmp .GetInputLoop

	.PageDown:
		inc dword [.currentDevice]
		mov eax, dword [tSystem.PCIDeviceCount]
		cmp dword [.currentDevice], eax
		jbe .PCIDevices
		dec dword [.currentDevice]
	jmp .GetInputLoop

	.End:
	; set this for next time
	mov dword [.currentDevice], 0

	; clear the screen and exit
	call ScreenClear32
ret

.WaitForEscape:
	; does exactly what it says
	push 0
	call KeyWait
	pop eax
	cmp al, 0x76
	jne .WaitForEscape
ret

section .data
.PCIInfoText$									db 'PCI Devices', 0x00
.PCIDeviceCountText$							db '^d PCI devices found', 0x00
.PCIDeviceListingText$							db 'Shadowed register space for device ^d of ^d', 0x00
.PCIDeviceDescriptionText1$						db 'Bus Dev  Fn  Vend  Dev   Cl  Sc  PI  Rv  Description', 0x00
.format$										db '^p2^h  ^p2^h   ^p1^h   ^p4^h  ^h  ^p2^h  ^h  ^h  ^h  ^s', 0x00
.PCIBus											dd 0x00000000
.PCIDevice										dd 0x00000000
.PCIFunction									dd 0x00000000
.currentDevice									dd 0x00000000

; struct to hold all data about a single PCI device for the system menu
PCIDeviceInfo:
.PCIVendorID									dw 0x0000
.PCIDeviceID									dw 0x0000
.PCICommand										dw 0x0000
.PCIStatus										dw 0x0000
.PCIRevision									db 0x00
.PCIProgIf										db 0x00
.PCISubclass									db 0x00
.PCIClass										db 0x00
.PCICacheLineSize								db 0x00
.PCILatencyTimer								db 0x00
.PCIHeaderType									db 0x00
.PCIBIST										db 0x00
.PCIBAR0										dd 0x00000000
.PCIBAR1										dd 0x00000000
.PCIBAR2										dd 0x00000000
.PCIBAR3										dd 0x00000000
.PCIBAR4										dd 0x00000000
.PCIBAR5										dd 0x00000000
.PCICardbusCISPointer							dd 0x00000000
.PCISubsystemVendorID							dw 0x0000
.PCISubsystemID									dw 0x0000
.PCIExpansionROMBaseAddress						dd 0x00000000
.PCICapabilitiesPointer							db 0x00
.PCIReserved									times 7 db 0x00
.PCIInterruptLine								db 0x00
.PCIInterruptPin								db 0x00
.PCIMaxGrant									db 0x00
.PCIMaxLatency									db 0x00
.PCIRegisters									times 192 db 0x00
PCITable:
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
kDebugger$										db 'What a horrible Night to have a bug.', 0x00
kSadThing$										db 0x27, 'Tis a sad thing that your process has ended here!', 0x00





section .text
DebugVBoxLogWrite:
	; Writes a string specidfied to the VirtualBox guest log
	;
	;  input:
	;   string address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; get the address of the string
	mov esi, [ebp + 8]
	
	; get the string's length
	push esi
	call StringLength
	pop ecx

	; save the length for later
	mov ebx, ecx
	
	; write to the log
	mov dx, 0x0504
	rep outsb

	; VirtualBox seems to buffer all output to the log and only flush on every 512th byte, as long as it's not null
	; we allow for this behaviour here
	mov ecx, 511
	sub ecx, ebx
	.hoop:
		mov dx, 0x504
		mov al, 0
		out dx, al
	loop .hoop

	mov esp, ebp
	pop ebp
ret 4





section .text
StackDump:
	; Traces the stack and prints a list of return addresses
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; set the starting point of our trace
	mov ebx, [esp]

	.TraceLoop:
		; see if we're done
		cmp ebx, 0
		je .done

		; load the previous stack frame's eip into edx
		mov edx, [ebx + 4]							

		; load the previous stack frame's ebp into ebx
		mov ebx, [ebx + 0]							
		
		; print the address we found
		pusha
		push edx
		push kPrintText$
		push .traceFormat$
		call StringBuild

		; print the string we just built
		push kPrintText$
		call Print32
		popa

	jmp	.TraceLoop

	.done:
	mov esp, ebp
	pop ebp
ret

section .data
.traceFormat$									db ' ^p8^h', 0x00
