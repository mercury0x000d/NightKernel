; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; pci.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; defines
%define kPCIAddressPort							0x0CF8
%define kPCIDataPort							0x0CFC





bits 16





section .text
PCIProbe:
	; Probes the PCI BIOS to see if it exists and saves version info to the tSystem struct
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp

	; execute the PCI BIOS call
	mov eax, 0xB101
	mov edi, 0
	int 0x1A

	; save the PCI capabilities
	mov dword [tSystem.PCICapabilities], eax

	; save the PCI version info
	mov dword [tSystem.PCIVersion], ebx

	mov sp, bp
	pop bp
ret





bits 32





section .text
PCICalculateNext:
	; Calculates the proper value of the next spot on the PCI bus
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	next PCI Bus
	;	next PCI Device
	;	next PCI Function

	push ebp
	mov ebp, esp

	mov ebx, [ebp + 8]
	mov edx, [ebp + 12]
	mov ecx, [ebp + 16]

	; add one to the data before checking for possible adjustments
	inc ecx

	.FunctionCheck:
	cmp ecx, 7
	jbe .DeviceCheck

	; if we get here, adjustment is needed
	mov ecx, 0x00000000
	inc edx

	.DeviceCheck:
	cmp edx, 31
	jbe .BusCheck

	; if we get here, adjustment is needed
	mov edx, 0x00000000
	inc ebx

	.BusCheck:
	cmp ebx, 255
	jbe .Done

	; if we get here, adjustment is needed
	mov ebx, 0x0000FFFF
	mov edx, 0x0000FFFF
	mov ecx, 0x0000FFFF

	.Done:
	; throw the new values on the stack and exit
	mov dword [ebp + 16], ebx
	mov dword [ebp + 12], edx
	mov dword [ebp + 8], ecx

	mov esp, ebp
	pop ebp
ret





section .text
PCICheckForFunction:
	; Checks the bus/device/function specified to see if there's something there
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	result
	;		kTrue - function was found
	;		kFalse - function was not found

	push ebp
	mov ebp, esp

	mov ebx, [ebp + 8]
	mov edx, [ebp + 12]
	mov ecx, [ebp + 16]

	; load the first register (vendor and device IDs) for this device
	push 0
	push ecx
	push edx
	push ebx
	call PCILiveRead
	pop eax

	; preset our result now
	mov ebx, dword [kFalse]

	; if the vendor ID is 0xFFFF, there's nothing here
	cmp ax, 0xFFFF
	je .Exit
		; if we get here, the device is valid
		mov ebx, dword [kTrue]
	.Exit:
	; the usual stack fixup and exit
	mov dword [ebp + 16], ebx

	mov esp, ebp
	pop ebp
ret 8





section .text
PCIDriverSearch:
	; Scans all the drivers in the kernel to see if any match the class/subclass/progif given and returns
	; a function pointer to the driver's init function if found, or zero if not found
	;
	;  input:
	;	PCI Class value
	;	PCI Subclass value
	;	PCI ProgIf value
	;
	;  output:
	;	driver init function address (or zero if no appropriate driver found)

	push ebp
	mov ebp, esp

	; start a loop here which will cycle until the driver signature is no longer found
	mov esi, DriverSpaceStart

	.DriverDiscoveryLoop:
		; preserve the search address
		push esi

		; search for the signature of the first driver
		push kDriverSignature$
		push dword 16
		push esi
		call MemSearchString
		pop edi

		; test the result
		cmp edi, 0
		jne .CheckPCI

		; if we get here, we got a zero back... so no driver was found
		jmp .NextIteration


		.CheckPCI:
		; sweet, we gots us a driver address! I wonder if it's a PCI driver...
		; modify edi to point to the driver flags
		add edi, 16

		; read the flags to see if we have a PCI driver
		mov ebx, [edi]

		and ebx, 00100000000000000000000000000000b
		cmp ebx, 00100000000000000000000000000000b
		je .CheckDeviceSupport

		; if we get here, it's not a PCI driver. back to the drawing board!
		jmp .NextIteration

		.CheckDeviceSupport:
		; well, ok, we have a PCI driver... let's see if it can handle this device!

		; get edi pointing to the start of the driver header values
		add edi, 4

		; clear our "flag" register for the following tests
		mov ebx, 0x00000000

		; check class first
		mov eax, [edi]
		cmp eax, dword [ebp + 8]
		je .CheckSubclass

		; if we get here, it didn't match
		inc ebx

		.CheckSubclass:
		add edi, 4
		mov eax, [edi]
		cmp eax, dword [ebp + 12]
		je .CheckProgIf

		; if we get here, it didn't match
		inc ebx

		.CheckProgIf:
		add edi, 4
		mov eax, [edi]
		cmp eax, dword [ebp + 16]
		je .DoneChecking

		; if we get here, it didn't match
		inc ebx

		.DoneChecking:
		cmp ebx, 0
		je .DriverIsAppropriate

		; if we get here, well... poor driver, you just won't do
		jmp .NextIteration

		.DriverIsAppropriate:
		; this driver should do the trick!
		; point edi to the start of the driver's init code
		add edi, 12
		jmp .DriverScanDone

		.NextIteration:
		; go back and scan again for another driver
		pop esi
		inc esi

		; exit if we're at the end of driver space
		cmp esi, DriverSpaceEnd
		je .DriverScanDone

	jmp .DriverDiscoveryLoop
	.DriverScanDone:
	; get rid of that extra copy of esi we saved earlier...
	pop esi

	; push the return value on the stack and exit
	mov dword [ebp + 16], edi

	mov esp, ebp
	pop ebp
ret 8





section .text
PCIGetFunctionCount:
	; Returns the total number of functions across all PCI busses in the system
	;
	;  input:
	;   dummy value
	;
	;  output:
	;   PCI device count

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 16
	%define PCIBus								dword [ebp - 4]
	%define PCIDevice							dword [ebp - 8]
	%define PCIFunction							dword [ebp - 12]
	%define PCIDeviceCount						dword [ebp - 16]


	; init the values
	mov PCIBus, 0
	mov PCIDevice, 0
	mov PCIFunction, 0
	mov PCIDeviceCount, 0

	; start the scanning loop
	.ScanLoop:
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCICheckForFunction
	pop eax

	; check to see if anything was there
	cmp eax, [kTrue]
	jne .NothingFound

	; if we get here, something was found, so increment the counter
	inc PCIDeviceCount

	.NothingFound:

	; increment to the next function slot
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCICalculateNext
	pop PCIFunction
	pop PCIDevice
	pop PCIBus

	; add all the values together to be tested
	mov eax, PCIBus
	add eax, PCIDevice
	add eax, PCIFunction

	; see if we're done, loop again if not
	cmp eax, 0x0002FFFD
	jne .ScanLoop

	; and we exit!
	mov eax, PCIDeviceCount
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret





section .text
PCIGetNextFunction:
	; Starts a scans at the bus/device/function specified to find the next function in order
	;
	;  input:
	;   starting PCI Bus
	;	starting PCI Device
	;	starting PCI Function
	;
	;  output:
	;   next occupied PCI Bus
	;	next occupied PCI Device
	;	next occupied PCI Function

	push ebp
	mov ebp, esp

	; start the scanning loop
	.ScanLoop:
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCICheckForFunction
	pop eax

	; check to see if anything was there
	cmp eax, [kFalse]
	je .NothingFound
	
	; if we get here, something was found
	jmp .Exit

	.NothingFound:
	; if we get here, nothing was found, so we keep scanning
	; increment to the next function slot
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCICalculateNext
	pop dword [ebp + 16]
	pop dword [ebp + 12]
	pop dword [ebp + 8]

	; add all the values together to be tested
	mov eax, dword [ebp + 8]
	add eax, dword [ebp + 12]
	add eax, dword [ebp + 16]

	; see if we're done, loop again if not
	cmp eax, 0x0002FFFD
	jne .ScanLoop

	.Exit:
	; reorder the parameters here, and exit
	mov eax, [ebp + 8]
	mov ebx, [ebp + 16]
	xchg eax, ebx
	mov [ebp + 8], eax
	mov [ebp + 16], ebx

	mov esp, ebp
	pop ebp
ret





section .text
PCIInitBus:
	; Scans all PCI busses and shadows all data to a List Manager list
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 16
	%define currentElement						dword [ebp - 4]
	%define PCIBus								dword [ebp - 8]
	%define PCIDevice							dword [ebp - 12]
	%define PCIFunction							dword [ebp - 16]


	; see how many PCI functions we have
	push 0
	call PCIGetFunctionCount
	pop eax
	mov [tSystem.PCIDeviceCount], eax

	; create a list with that many entries of 268 bytes each
	; functions * 268 + 16 = mem reqeust
	mov ebx, 268
	mul ebx
	add eax, 16

	; allocate memory for the list
	push eax
	push dword 1
	call MemAllocate
	pop edi
	mov [tSystem.listPCIDevices], edi

	; check to make sure we didn't get a null address
	cmp edi, 0
	jne .AddressValid
	mov eax, 0xDEAD0100
	jmp $

	.AddressValid:
	; set up the list header
	push 268
	push dword [tSystem.PCIDeviceCount]
	push edi
	call LMListInit
	
	; cycle through all busses and devices on those busses, copying all registers into RAM
	; clear the values
	mov currentElement, 0
	mov PCIBus, 0
	mov PCIDevice, 0
	mov dword [ebp - 16], 0

	.FunctionLoop:
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIGetNextFunction
		pop PCIFunction
		pop PCIDevice
		pop PCIBus

		; see if we're done yet
		mov eax, PCIBus
		add eax, PCIDevice
		add eax, PCIFunction
		cmp eax, 0x0002FFFD
		je .LoopDone

		; now that we have a valid device, let's copy all the registers

		; set up the target address
		push currentElement
		push dword [tSystem.listPCIDevices]
		call LMElementAddressGet
		pop esi
		; ignore error code
		pop eax

		; copy PCI bus location info to the table
		mov eax, PCIBus
		mov [esi], eax
		add esi, 4

		mov eax, PCIDevice
		mov [esi], eax
		add esi, 4

		mov eax, PCIFunction
		mov [esi], eax
		add esi, 4

		; set the number of PCI register reads we need to do
		mov ecx, 64
		mov edx, 0

		; start the loop to copy all the info
		.ReadLoop:
			; save important stuff
			push esi
			push ecx
			push edx

			; adjust ecx to point to the correct PCI register
			dec ecx

			; get the register
			push edx
			push PCIFunction
			push PCIDevice
			push PCIBus
			call PCILiveRead
			pop eax

			; restore important stuff
			pop edx
			pop ecx
			pop esi

			; write the register to the struct and increment destination
			mov [esi], eax

			; adjust the destination address and register counter
			inc edx
			add esi, 4

		loop .ReadLoop

		; advance to the next slot
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCICalculateNext
		pop PCIFunction
		pop PCIDevice
		pop PCIBus

		; move to the next element
		inc currentElement

	jmp .FunctionLoop

	.LoopDone:

	mov esp, ebp
	pop ebp
ret





section .text
PCILiveRead:
	; Reads a 32-bit register value from the PCI target specified
	; Note: This function reads directly from the PCI bus, not from the shadowed PCI data in RAM
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;
	;  output:
	;   register value

	push ebp
	mov ebp, esp

	; we start by building a value out of the bus, device, function and register values provided
	mov eax, 0x00000000							; clear the destination
	mov ebx, [ebp + 8]							; load the PCI bus provided
	and ebx, 0x000000FF							; PCI busses are 8 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 5									; shift left 5 bits to get ready for the next section

	mov ebx, [ebp + 12]							; load the PCI device provided
	and ebx, 0x0000001F							; PCI devices are 5 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 3									; shift left 3 bits to get ready for the next section

	mov ebx, [ebp + 16]							; load the PCI function provided
	and ebx, 0x00000007							; PCI functions are 3 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 6									; shift left 6 bits to get ready for the next section

	mov ebx, [ebp + 20]							; load the PCI registers provided
	and ebx, 0x0000003F							; PCI registers are 6 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 2									; shift left 2 bits to finalize and align

	or eax, 0x80000000							; set bit 31 to enable configuration

	; write the value we just built to select the proper target
	mov dx, kPCIAddressPort
	out dx, eax

	; read the register back
	mov dx, kPCIDataPort
	in eax, dx

	;push the result
	mov dword [ebp + 20], eax

	mov esp, ebp
	pop ebp
ret 12





section .text
PCILiveWrite:
	; Writes a 32-bit value to the target PCI register specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;	value to write
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; we start by building a value out of the bus, device, function and register values provided
	mov eax, 0x00000000							; clear the destination
	mov ebx, [ebp + 8]							; load the PCI bus provided
	and ebx, 0x000000FF							; PCI registers are 8 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 5									; shift left 5 bits to get ready for the next section

	mov ebx, [ebp + 12]							; load the PCI device provided
	and ebx, 0x0000001F							; PCI devices are 5 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 3									; shift left 3 bits to get ready for the next section

	mov ebx, [ebp + 16]							; load the PCI function provided
	and ebx, 0x00000007							; PCI functions are 3 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 6									; shift left 6 bits to get ready for the next section

	mov ebx, [ebp + 20]							; load the PCI registers provided
	and ebx, 0x0000003F							; PCI registers are 6 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 2									; shift left 2 bits to finalize and align

	or eax, 0x80000000							; set bit 31 to enable configuration

	; write the value we just built to select the proper target
	mov dx, kPCIAddressPort
	out dx, eax

	; get the value to write from the stack
	mov eax, [ebp + 24]

	; write the data register
	mov dx, kPCIDataPort
	out dx, eax

	mov esp, ebp
	pop ebp
ret 24





section .text
PCILoadDrivers:
	; Cycles through all functions in the PCI list and loads drivers for each
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a
	;

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 24
	%define PCIBus								dword [ebp - 4]
	%define PCIDevice							dword [ebp - 8]
	%define PCIFunction							dword [ebp - 12]
	%define PCIClass							dword [ebp - 16]
	%define PCISubclass							dword [ebp - 20]
	%define PCIProgIf							dword [ebp - 24]


	; first get the number of elements in the PCI list
	push dword 0
	push dword [tSystem.listPCIDevices]
	call LMElementCountGet
	pop ecx
	pop eax

	; adjust ecx to be in range
	dec ecx

	.DriverLoop:
		push ecx

		; get the address of this PCI function from the list
		push ecx
		push dword [tSystem.listPCIDevices]
		call LMElementAddressGet
		pop esi
		; ignore error code
		pop eax

		; get the PCI function data from the list
		mov eax, dword [esi]
		mov PCIBus, eax
		add esi, 4
		mov eax, dword [esi]
		mov PCIDevice, eax
		add esi, 4
		mov eax, dword [esi]
		mov PCIFunction, eax

		; clear our print string
		push dword 0
		push dword 256
		push kPrintText$
		call MemFill

		; now that we have a function, let's see if any drivers will be a good fit

		; maybe make these three separate routines in the future for handiness?
		; get the class, subclass, and progif values for this device so we can search for a suitable driver
		push dword 0x00000002
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIReadDWord
		pop eax

		; juggle the bytes here to transfer the proper data into our variables
		shr eax, 8
		mov ebx, eax
		and ebx, 0x000000FF
		mov PCIProgIf, ebx

		shr eax, 8
		mov ebx, eax
		and ebx, 0x000000FF
		mov PCISubclass, ebx

		shr eax, 8
		mov ebx, eax
		and ebx, 0x000000FF
		mov PCIClass, ebx


		; tell the user what we're doing here
		push PCIProgIf
		push PCISubclass
		push PCIClass
		push PCIFunction
		push PCIDevice
		push PCIBus
		push kPrintText$
		push .locatingDriver$
		call StringBuild
		push kPrintText$
		call PrintIfConfigBits32

		; check for a function driver (that is, one for the exact ProgIf value)
		; search for precise driver first for this exact class/subclass/prog if 
		push PCIProgIf
		push PCISubclass
		push PCIClass
		call PCIDriverSearch
		pop eax

		; test the result of the search
		cmp eax, 0
		je .CheckForSubclassDriver


		; if we get here, the driver was found so we first say what's going on
		push eax
		push .exactDriverFound$
		call PrintIfConfigBits32
		pop eax
		
		; now we can run the driver's init code
		push 0
		push PCIFunction
		push PCIDevice
		push PCIBus
		call eax
		pop ecx

		; and we now can go to the next driver search
		jmp .NextIteration



		.CheckForSubclassDriver:
		; if we get here, a suitable driver wasn't found, so now we'll search for a driver that handles
		; the entire subclass (all prog if values)
		push dword 0x0000FFFF
		push PCISubclass
		push PCIClass
		call PCIDriverSearch
		pop eax

		; test the result of the search
		cmp eax, 0
		je .CheckForClassDriver


		; if we get here, the driver was found so we first say what's going on
		push eax
		push .subclassDriverFound$
		call PrintIfConfigBits32
		pop eax
		
		; now we can run the driver's init code
		push 0
		push PCIFunction
		push PCIDevice
		push PCIBus
		call eax
		pop ecx

		; and we now can go to the next driver search
		jmp .NextIteration


		.CheckForClassDriver:
		; still nothing?!? ok, search for a driver for the entire class (all subclasses and prog if values)
		push dword 0x0000FFFF
		push dword 0x0000FFFF
		push PCIClass
		call PCIDriverSearch
		pop eax

		; test the result of the search
		cmp eax, 0
		je .WeAreCompletelyDriverless


		; if we get here, the driver was found so we first say what's going on
		push eax
		push .classDriverFound$
		call PrintIfConfigBits32
		pop eax
		
		; now we can run the driver's init code
		push 0
		push PCIFunction
		push PCIDevice
		push PCIBus
		call eax
		pop ecx

		; and we now can go to the next driver search
		jmp .NextIteration


		.WeAreCompletelyDriverless:
		; what?? ok, fine. there's just no driver in the kernel for this device
		; tell the good folks that no driver was found, Gracie
		push .noDriver$
		call PrintIfConfigBits32

		.NextIteration:
		pop ecx

		; skip a line for clarity
		inc byte [cursorY]

	; I would've used "loop" here, but the code the loop contains is too big :/
	; and for some reason, VirtualBox (or the processor itself?) doesn't properly set the overflow flag on some machines
	dec ecx
    cmp ecx, 0xFFFFFFFF
    jne .DriverLoop

	mov esp, ebp
	pop ebp
ret

section .data
.locatingDriver$								db 'Locating driver for ^p3^d-^p2^d-^d (Class 0x^h, Subclass 0x^h, ProgIf 0x^h)', 0x00
.exactDriverFound$								db 'Function driver found, running Init...', 0x00
.subclassDriverFound$							db 'Subclass driver found, running Init...', 0x00
.classDriverFound$								db 'Class driver found, running Init...', 0x00
.noDriver$										db 'No driver found, continuing', 0x00





section .text
PCIReadAll:
	; Gets all info for the specified PCI device and fills it into the struct at the given address
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI info struct address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; set the number of reads we need to do
	mov ecx, 64

	; start the loop to copy all the info
	.ReadLoop:
		; adjust ecx to point to the correct PCI register
		dec ecx

		push ecx

		; get the register
		push ecx
		push dword [ebp + 16]
		push dword [ebp + 12]
		push dword [ebp + 8]
		call PCIReadDWord
		pop eax

		pop ecx

		; calculate the write address
		mov esi, [ebp + 20]
		mov edi, esi
		mov edx, ecx
		shl edx, 2
		add edi, edx

		; adjust ecx back to normal
		inc ecx

		; write the register to the struct
		mov [edi], eax

	loop .ReadLoop

	mov esp, ebp
	pop ebp
ret 16





section .text
PCIReadByte:
	; Reads a byte register from the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;
	;  output:
	;   Register value

	; scan the list for the proper device

ret





section .text
PCIReadWord:
	; Reads a word register from the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;
	;  output:
	;   Register value

	; scan the list for the proper device

ret





section .text
PCIReadDWord:
	; Reads a dword register from the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;
	;  output:
	;   Register value

	push ebp
	mov ebp, esp

	; scan the list for the proper device
	mov ecx, dword [tSystem.listPCIDevices]
	add ecx, 16

	.RegisterSearchLoop:
		; set the check flag for the following tests
		mov eax, 0x00000000

		; read the next dword from the table
		mov edx, [ecx]

		; see if it's an invalid bus
		cmp edx, 0xFFFFFFFF
		je .PCISearchExit

		; see if we have a match
		cmp edx, [ebp + 8]
		je .PCISearchSkip1

		; if we get here, it wasn't a match, so we adjust the flag register
		or eax, 00000000000000000000000000000001b
		.PCISearchSkip1:



		; increment ecx to check the next number
		add ecx, 4

		; read the next dword from the table
		mov edx, [ecx]

		; see if it's an invalid device
		cmp edx, 0xFFFFFFFF
		je .PCISearchExit

		; see if we have a match
		cmp edx, [ebp + 12]
		je .PCISearchSkip2

		; if we get here, it wasn't a match, so we adjust the flag register
		or eax, 00000000000000000000000000000010b
		.PCISearchSkip2:



		; increment ecx to check the next number
		add ecx, 4

		; read the next dword from the table
		mov edx, [ecx]

		; see if it's an invalid function
		cmp edx, 0xFFFFFFFF
		je .PCISearchExit

		; see if we have a match
		cmp edx, [ebp + 16]
		je .PCISearchSkip3

		; if we get here, it wasn't a match, so we adjust the flag register
		or eax, 00000000000000000000000000000100b
		.PCISearchSkip3:



		; check the result of the previous tests
		cmp eax, 0x00000000
		jne .PCISearchNoMatch


		; if we get here, it's a match
		; adjust ecx to point to first register
		add ecx, 4

		; adjust ecx to point to the specific register requested
		mov edx, dword [ebp + 20]

		; multiply the register by 4 to mimic how the real PCI system handles register numbers
		rol edx, 2

		; truncate edx for safety
		and edx, 0xFF

		; add the register offset to the table address to pinpoint the register we need
		add ecx, edx

		; load the register data
		mov edx, [ecx]

		; we got the register value in edx, so we can exit
		jmp .PCISearchExit



		.PCISearchNoMatch:
		; adjust the ecx pointer to the next device in the table
		add ecx, 260

	jmp .RegisterSearchLoop

	.PCISearchExit:

	; return value and exit
	mov dword [ebp + 20], edx

	mov esp, ebp
	pop ebp
ret 12





section .text
PCIWriteByte:
	; Writes a byte value to the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;	Register value
	;
	;  output:
	;   n/a

ret





section .text
PCIWriteWord:
	; Writes a word value to the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;	Register value
	;
	;  output:
	;   n/a

ret





section .text
PCIWriteDword:
	; Writes a dword value to the PCI target specified
	;
	;  input:
	;   PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;	Register value
	;
	;  output:
	;   n/a

ret
