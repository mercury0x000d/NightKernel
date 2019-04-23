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
; DebugInstacrash				Causes an instant crash
; DebugMemoryDetails			Displays memory allocation
; DebugMenu						Implements the in-kernel debugging menu
; DebugPCIDevices				Displays all PCI devices in the system
; DebugRAMBrowser				An interactive memory broswer
; DebugStackTrace				Traces the stack and prints a list of return addresses
; DebugSystemInfo				Displays information about the system on which Night is running
; DebugVBOXLogWrite				Writes a string specidfied to the VirtualBOX guest log
; DebugWaitForEscape			Waits for the Escape key to be pressed, then returns


global DebugInstacrash, DebugMemoryDetails, DebugMenu, DebugPCIDevices,\
	   DebugRAMBrowser, DebugStackTrace, DebugSystemInfo, DebugVBOXLogWrite,\
	   DebugWaitForEscape

extern MemCopy, Print32, PrintRAM32, StringTokenHexadecimal, LMElementAddressGet,\
	   ScreenClear32, StringCharAppend, StringTruncateLeft, StringTokenString,\
	   LMItemAddAtSlot,PCIGetNextFunction, KeyGet, Reboot, MemAllocate,\
	   LMListInit, PCIReadAll, PCICalculateNext, StringTokenDecimal, KeyWait, kMaxLines,\
	   ConvertStringHexToNumber, StringLength, LMElementCountGet

%include "include/globals.inc"
%include "include/memory.inc"
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

bits 32

section .text
DebugInstacrash:
	; DebugInstacrash				Causes an instant crash
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


 	; invalid opcode exception
	db 0xF0, 0xFF, 0xFF

	; GPF
	db 0xFF, 0xFF
ret





section .text
DebugMemoryDetails:
	; DebugMemoryDetails			Displays memory allocation
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
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
	push .memoryDetailsHeader$
	call Print32
	pop eax
	pop eax


	; set up a loop to step through all elements in the memory list for printing
	push dword 0
	push dword [tSystem.listMemory]
	call LMElementCountGet
	pop ecx
	pop edx
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
		pop esi
		; ignore error code
		pop ecx


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
		push dword [tMemInfo.address]
		push .scratch$
		call StringTokenHexadecimal

		; restore and re-save esi
		pop esi
		push esi

		push dword 8
		push dword [tMemInfo.size]
		push .scratch$
		call StringTokenHexadecimal

		; restore esi
		pop esi

		push dword 2
		push dword [tMemInfo.task]
		push .scratch$
		call StringTokenHexadecimal

		push dword 0x00000000
		push dword 0x00000007
		push dword cursorY
		push dword 1
		push .scratch$
		call Print32
		pop eax
		pop cursorY

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
	;   n/a
	;
	;  output:
	;   n/a

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
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
	push .debugText1$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 4
	push dword 1
	push .debugText2$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 5
	push dword 1
	push .debugText3$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 6
	push dword 1
	push .debugText4$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 7
	push dword 1
	push .debugText5$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 8
	push dword 1
	push .debugText6$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 9
	push dword 1
	push .debugText7$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 10
	push dword 1
	push .debugText8$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 11
	push dword 1
	push .debugText9$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 12
	push dword 1
	push .debugText0$
	call Print32
	pop eax
	pop eax

	push dword 0x00000000
	push dword 0x00000007
	push dword 14
	push dword 1
	push .escMessage$
	call Print32
	pop eax
	pop eax

	.DebugLoop:
		push 0
		call KeyGet
		pop eax

		cmp al, 0x45							; choice 0
		jne .TestFor1
		call Reboot
		jmp .DrawMenu

		.TestFor1:
		cmp al, 0x16							; choice 1
		jne .TestFor2
		call DebugSystemInfo
		jmp .DrawMenu

		.TestFor2:
		cmp al, 0x1E							; choice 2
		jne .TestFor3
		call DebugPCIDevices
		jmp .DrawMenu

		.TestFor3:
		cmp al, 0x26							; choice 3
		jne .TestFor4
		call DebugMemoryDetails
		jmp .DrawMenu

		.TestFor4:
		cmp al, 0x25							; choice 4
		jne .TestFor5
		call DebugRAMBrowser
		jmp .DrawMenu

		.TestFor5:
		cmp al, 0x2E							; choice 5
		jne .TestFor6
		; put something here to jump to!
		jmp .DrawMenu

		.TestFor6:
		cmp al, 0x36							; choice 6
		jne .TestFor7
		; put something here to jump to!
		jmp .DrawMenu

		.TestFor7:
		cmp al, 0x3D							; choice 7
		jne .TestFor8
		; put something here to jump to!
		jmp .DrawMenu

		.TestFor8:
		cmp al, 0x3E							; choice 8
		jne .TestFor9
		; put something here to jump to!
		jmp .DrawMenu

		.TestFor9:
		cmp al, 0x46							; choice 9
		jne .DebugLoop
		call DebugInstacrash
		jmp .DrawMenu

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
.debugText5$									db '5 - ', 0x00
.debugText6$									db '6 - ', 0x00
.debugText7$									db '7 - ', 0x00
.debugText8$									db '8 - ', 0x00
.debugText9$									db '9 - Crash. Yes, really. Relax, it', 0x27,'s just for testing.', 0x00
.debugText0$									db '0 - Reboot', 0x00
.escMessage$									db 'Press Escape from any sub menu above to return to this main menu', 0x00
.debuggerMessage$								db 'What a horrible Night to have a bug.', 0x00

section .bss
.scratch$										resb 80





section .text
DebugPCIDevices:
	; DebugPCIDevices				Displays all PCI devices in the system
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	; create a new list to hold the PCI device labels if necessary
	cmp byte [.flag], 1
	je .PCIInitSkip

		; if we get here, this hasn't been set up yet... so let's do so!

		; the list will be 256 entries of 36 bytes each
		; 256 * 36 + 16 = 9232 (0x2410)
		; allocate memory for the list
		push 9232
		push dword 1
		call MemAllocate
		pop edi

		mov [PCIDeviceInfo.PCIClassTable], edi

		; set up the list header
		push 36
		push 256
		push edi
		call LMListInit


		; write all the strings to the list area
		push dword 20
		push PCIDeviceInfo.PCI00$
		push dword 0
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 24
		push PCIDeviceInfo.PCI01$
		push dword 1
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 19
		push PCIDeviceInfo.PCI02$
		push dword 2
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 19
		push PCIDeviceInfo.PCI03$
		push dword 3
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 22
		push PCIDeviceInfo.PCI04$
		push dword 4
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 18
		push PCIDeviceInfo.PCI05$
		push dword 5
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 14
		push PCIDeviceInfo.PCI06$
		push dword 6
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 32
		push PCIDeviceInfo.PCI07$
		push dword 7
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 26
		push PCIDeviceInfo.PCI08$
		push dword 8
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 13
		push PCIDeviceInfo.PCI09$
		push dword 9
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 16
		push PCIDeviceInfo.PCI0A$
		push dword 10
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 10
		push PCIDeviceInfo.PCI0B$
		push dword 11
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 15
		push PCIDeviceInfo.PCI0C$
		push dword 12
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 20
		push PCIDeviceInfo.PCI0D$
		push dword 13
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 27
		push PCIDeviceInfo.PCI0E$
		push dword 14
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 36
		push PCIDeviceInfo.PCI0F$
		push dword 15
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 22
		push PCIDeviceInfo.PCI10$
		push dword 16
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 29
		push PCIDeviceInfo.PCI11$
		push dword 17
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 23
		push PCIDeviceInfo.PCI12$
		push dword 18
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 30
		push PCIDeviceInfo.PCI13$
		push dword 19
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 12
		push PCIDeviceInfo.PCI40$
		push dword 64
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax

		push dword 17
		push PCIDeviceInfo.PCIFF$
		push dword 255
		push dword [PCIDeviceInfo.PCIClassTable]
		call LMItemAddAtSlot
		pop eax
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
	pop eax
	pop eax

	; see if we have to print data on all devices of on a specific device
	cmp dword [.currentDevice], 0
	jne .PrintSpecificDevice
	
		; if we get here, the index is 0 so we print all devices
	
		; build and print the device count string
		push 80
		push .scratch$
		push .PCIDeviceCountText$
		call MemCopy

		push dword 0
		push dword [tSystem.PCIDeviceCount]
		push .scratch$
		call StringTokenHexadecimal

		push dword 0x00000000
		push dword 0x00000007
		push dword 1
		push dword 13
		push .scratch$
		call Print32
		pop eax
		pop eax


		; print the device description header
		push dword 0x00000000
		push dword 0x00000007
		push dword 3
		push dword 1
		push .PCIDeviceDescriptionText1$
		call Print32
		pop eax
		pop eax


		; init the values
		mov dword [.PCIBus], 0
		mov dword [.PCIDevice], 0
		mov dword [.PCIFunction], 0

		mov cursorY, 4
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
			push dword [PCIDeviceInfo.PCIClassTable]
			call LMElementAddressGet
			pop edx
			; ignore error code
			pop ecx

			; save the address for later
			push edx

			; build the rest of the PCI data into line 1 for this device
			push 80
			push .scratch$
			push .format$
			call MemCopy

			push dword 2
			push dword [.PCIBus]
			push .scratch$
			call StringTokenHexadecimal

			push dword 2
			push dword [.PCIDevice]
			push .scratch$
			call StringTokenHexadecimal

			push dword 1
			push dword [.PCIFunction]
			push .scratch$
			call StringTokenHexadecimal

			push dword 4
			mov eax, 0x00000000
			mov ax, [PCIDeviceInfo.PCIVendorID]
			push eax
			push .scratch$
			call StringTokenHexadecimal

			push dword 4
			mov eax, 0x00000000
			mov ax, [PCIDeviceInfo.PCIDeviceID]
			push eax
			push .scratch$
			call StringTokenHexadecimal

			push dword 2
			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIClass]
			push eax
			push .scratch$
			call StringTokenHexadecimal

			push dword 2
			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCISubclass]
			push eax
			push .scratch$
			call StringTokenHexadecimal

			push dword 2
			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIProgIf]
			push eax
			push .scratch$
			call StringTokenHexadecimal

			push dword 2
			mov eax, 0x00000000
			mov al, [PCIDeviceInfo.PCIRevision]
			push eax
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
			push dword cursorY
			push dword 1
			push .scratch$
			call Print32
			pop eax
			pop cursorY

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
	push 80
	push .scratch$
	push .PCIDeviceListingText$
	call MemCopy

	push dword 0
	push dword [.currentDevice]
	push .scratch$
	call StringTokenDecimal

	push dword 0
	push dword [tSystem.PCIDeviceCount]
	push .scratch$
	call StringTokenDecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


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
	push dword 0x00000000
	push dword 0x00000007
	push dword 3
	push dword 1
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
		jne DebugPCIDevices
		inc dword [.currentDevice]
	jmp .GetInputLoop

	.PageDown:
		inc dword [.currentDevice]
		mov eax, dword [tSystem.PCIDeviceCount]
		cmp dword [.currentDevice], eax
		jbe DebugPCIDevices
		dec dword [.currentDevice]
	jmp .GetInputLoop

	.End:
	; set this for next time
	mov dword [.currentDevice], 0

	; clear the screen and exit
	push 0x00000000
	call ScreenClear32
ret

section .bss
.scratch$										resb 80

section .data
.flag											db 0x00
.PCIInfoText$									db 'PCI Devices', 0x00
.PCIDeviceCountText$							db '(^ found)', 0x00
.PCIDeviceListingText$							db 'Shadowed register space for device ^ of ^', 0x00
.PCIDeviceDescriptionText1$						db 'Bus Dev  Fn  Vend  Dev   Cl  Sc  PI  Rv  Description', 0x00
.format$										db '^  ^   ^   ^  ^  ^  ^  ^  ^  ^', 0x00
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
	; DebugRAMBrowser				An interactive memory broswer
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
	pop eax
	pop eax


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
		pop eax
		pop eax

		mov eax, numLines
		add eax, 5
		push dword 0x00000000
		push dword 0x00000007
		push eax
		push dword 37
		push .JumpString$
		call Print32
		pop eax
		pop eax


		; get a keypress and handle it
		push 0
		call KeyGet
		pop eax


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
			pop eax
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
		pop eax
		pop eax


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
	; DebugSystemInfo				Displays information about the system on which Night is running
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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
	pop eax
	pop eax


	; print the kernel string
	push dword 0x00000000
	push dword 0x00000007
	push dword 5
	push dword 1
	push tSystem.copyright$
	call Print32
	pop eax
	pop eax


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

	push dword 0x00000000
	push dword 0x00000007
	push dword 7
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; print the CPU string
	push dword 0x00000000
	push dword 0x00000007
	push dword 9
	push dword 1
	push tSystem.CPUIDBrand$
	call Print32
	pop eax
	pop eax


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
	pop eax
	pop eax


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
	push dword 13
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


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
	push dword 15
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; build and print the PCI Devices List string
	push 80
	push .scratch$
	push .listPCIDevicesFormat$
	call MemCopy

	push dword 8
	push dword [tSystem.listPCIDevices]
	push .scratch$
	call StringTokenHexadecimal

	push dword 0x00000000
	push dword 0x00000007
	push dword 17
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


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
	push dword 19
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; ESC lets us leave, kids
	call DebugWaitForEscape

	; clear the screen and exit!
	push 0x00000000
	call ScreenClear32
ret

section .data
.systemInfoText$								db 'System Information', 0x00
.versionFormat$									db 'Kernel version ^.^', 0x00
.listDriveFormat$								db 'Drive List                0x^', 0x00
.listPartitionFormat$							db 'Partition List            0x^', 0x00
.listPCIDevicesFormat$							db 'PCI Devices List          0x^', 0x00
.listTasksFormat$								db 'Tasks List                0x^', 0x00
.listMemoryFormat$								db 'Memory List               0x^', 0x00

section .bss
.scratch$										resb 80





section .text
DebugVBoxLogWrite:
	; Writes the string specidfied to the VirtualBox guest log
	;
	;  input:
	;   string address
	;
	;  output:
	;   n/a


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
	.logWriteLoop:
		mov dx, 0x504
		mov al, 0
		out dx, al
	loop .logWriteLoop

ret 4





section .text
DebugWaitForEscape:
	; DebugWaitForEscape			Waits for the Escape key to be pressed, then returns
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	push 0
	call KeyWait
	pop eax
	cmp al, 0x76
	jne DebugWaitForEscape

ret
