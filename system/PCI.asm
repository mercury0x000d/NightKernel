; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; PCI.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/PCIDefines.inc"

%include "include/boolean.inc"
%include "include/errors.inc"
%include "include/globals.inc"
%include "include/lists.inc"
%include "include/memory.inc"
%include "include/screen.inc"
%include "include/strings.inc"





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


	.Exit:
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
	;	EAX - Next PCI Bus
	;	EBX - Next PCI Device
	;	ECX - Next PCI Function

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	mov eax, PCIBus
	mov ebx, PCIDevice
	mov ecx, PCIFunction

	; add one to the data before checking for possible adjustments
	inc ecx

	.FunctionCheck:
	cmp ecx, 7
	jbe .DeviceCheck

	; if we get here, adjustment is needed
	mov ecx, 0x00000000
	inc ebx

	.DeviceCheck:
	cmp ebx, 31
	jbe .BusCheck

	; if we get here, adjustment is needed
	mov ebx, 0x00000000
	inc eax

	.BusCheck:
	cmp eax, 255
	jbe .Exit

	; if we get here, adjustment is needed
	mov eax, 0x0000FFFF
	mov ebx, 0x0000FFFF
	mov ecx, 0x0000FFFF


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIDeviceInitAll:
	; Sends an init command to each present driver for each detected PCI device
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 28
	%define PCIBus								dword [ebp - 4]
	%define PCIDevice							dword [ebp - 8]
	%define PCIFunction							dword [ebp - 12]
	%define PCIClass							dword [ebp - 16]
	%define PCISubclass							dword [ebp - 20]
	%define PCIProgIf							dword [ebp - 24]
	%define PCIRegister							dword [ebp - 28]


	; init the values to outlandishly high numbers so that the next function will find the first device, usually at 000-00-00
	mov PCIBus, 0xFFFFFFFF
	mov PCIDevice, 0xFFFFFFFF
	mov PCIFunction, 0xFFFFFFFF

	.PCILoop:
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
		je .Exit

		; tell the user what we're doing next
		push 80
		push .scratch$
		push .sendingInit$
		call MemCopy

		; get the first 32-bit register which contains the PIC Vendor and Device ID
		push dword 0
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIRegisterRead
		mov PCIRegister, eax

		; add the Vendor and Device ID to the string
		and eax, 0x0000FFFF
		push dword 4
		push eax
		push .scratch$
		call StringTokenHexadecimal

		mov eax, PCIRegister
		shr eax, 16
		push dword 4
		push eax
		push .scratch$
		call StringTokenHexadecimal

		; get the third 32-bit register which contains the Class, Subclass, ProgIf, and Revision
		push dword 2
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIRegisterRead
		mov PCIRegister, eax

		; add the Class to the string
		shr eax, 24
		and eax, 0x000000FF
		push dword 2
		push eax
		push .scratch$
		call StringTokenHexadecimal

		; add the Subclass to the string
		mov eax, PCIRegister
		shr eax, 16
		and eax, 0x000000FF
		push dword 2
		push eax
		push .scratch$
		call StringTokenHexadecimal

		; add the ProgIf to the string
		mov eax, PCIRegister
		shr eax, 8
		and eax, 0x000000FF
		push dword 2
		push eax
		push .scratch$
		call StringTokenHexadecimal

		; add the Revision to the string
		mov eax, PCIRegister
		and eax, 0x000000FF
		push dword 2
		push eax
		push .scratch$
		call StringTokenHexadecimal

		push dword 3
		push PCIBus
		push .scratch$
		call StringTokenDecimal

		push dword 2
		push PCIDevice
		push .scratch$
		call StringTokenDecimal

		push dword 2
		push PCIFunction
		push .scratch$
		call StringTokenDecimal

		; and print it!
		push .scratch$
		call PrintIfConfigBits32


		; now send an init command to the driver for this device type
		push 0
		push 0
		push 0
		push 0
		push 0
		push kDriverInit
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIHandlerCommand

		; evaluate result
		cmp edx, kErrNone
		je .NextIteration

			; If we get here, there was an error. Let's see what it was.
			cmp edx, kErrHandlerNotPresent
			jne .NotHandlerNotPresent
				push .noDriver$
				call PrintIfConfigBits32
			.NotHandlerNotPresent:

		.NextIteration:
	jmp .PCILoop


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef PCIClass
	%undef PCISubclass
	%undef PCIProgIf
	%undef PCIRegister
	mov esp, ebp
	pop ebp
ret

section .data
.sendingInit$									db 'Sending Init for device ^:^ (^-^-^-^) at ^-^-^', 0x00
.noDriver$										db 'No driver found, continuing', 0x00

section .bss
.scratch$										resb 80





section .text
PCIFunctionCheck:
	; Checks the bus/device/function specified to see if there's something there
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	EDX - Result
	;		True - function was found
	;		False - function was not found

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	; load the first register (vendor and device IDs) for this device
	push 0
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	; preset our result now
	mov edx, false

	; if the vendor ID is 0xFFFF, there's nothing here
	cmp ax, 0xFFFF
	je .Exit

	; if we get here, the device is valid
	mov edx, true


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIFunctionCountGet:
	; Returns the total number of functions across all PCI busses in the system
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EAX - Function count

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
		call PCIFunctionCheck

		; check to see if anything was there
		cmp edx, true
		jne .NothingFound

		; if we get here, something was found, so increment the counter
		inc PCIDeviceCount

		.NothingFound:

		; increment to the next function slot
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCICalculateNext
		mov PCIBus, eax
		mov PCIDevice, ebx
		mov PCIFunction, ecx

		; add all the values together to be tested
		mov eax, PCIBus
		add eax, PCIDevice
		add eax, PCIFunction

		; see if we're done, loop again if not
		cmp eax, 0x0002FFFD
	jne .ScanLoop

	; and we exit!
	mov eax, PCIDeviceCount


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef PCIDeviceCount
	mov esp, ebp
	pop ebp
ret





section .text
PCIFunctionNextGet:
	; Starts a scan at the bus/device/function specified to find the next function in order
	;
	;  input:
	;	starting PCI Bus
	;	starting PCI Device
	;	starting PCI Function
	;
	;  output:
	;	EAX - Next occupied PCI Bus
	;	EBX - Next occupied PCI Device
	;	ECX - Next occupied PCI Function

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	; start the scanning loop
	.ScanLoop:

		; advance to the next slot
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCICalculateNext

		; add all the values together to see if we're done and loop again if not (acts as a timeout of sorts)
		mov edx, eax
		add edx, ebx
		add edx, ecx
		cmp edx, 0x0002FFFD
		je .Exit

		; save the values
		mov PCIBus, eax
		mov PCIDevice, ebx
		mov PCIFunction, ecx

		; check to see if anything is here
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIFunctionCheck

		cmp edx, false
		je .NothingFound
			; if we get here, something was found
			mov eax, PCIBus
			mov ebx, PCIDevice
			mov ecx, PCIFunction
			jmp .Exit
		.NothingFound:

		; if we get here, nothing was found, so scan again
	jmp .ScanLoop


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIHandlerCommand:
	; Sends a command to the handler of the PCI device specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	Command code
	;	Parameter 1
	;	Parameter 2
	;	Parameter 3
	;	Parameter 4
	;	Parameter 5
	;
	;  output:
	;	Varies by command
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define commandCode							dword [ebp + 20]
	%define parameter1							dword [ebp + 24]
	%define parameter2							dword [ebp + 28]
	%define parameter3							dword [ebp + 32]
	%define parameter4							dword [ebp + 36]
	%define parameter5							dword [ebp + 40]


	; define local variables
	sub esp, 12
	%define handlerAddress						dword [ebp - 4]
	%define PCIClass							dword [ebp - 8]
	%define PCISubclass							dword [ebp - 12]


	; start by getting the class
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIInfoClassGet
	mov PCIClass, eax

	; now get the subclass
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIInfoSubclassGet
	mov PCISubclass, eax


	; get the handler's address
	push PCISubclass
	push PCIClass
	call PCIHandlerGet
	mov handlerAddress, eax


	; if address is zero, we abort with error
	mov edx, kErrHandlerNotPresent
	cmp eax, 0
	je .Exit

	; set up a call to the handler for this device
	push parameter5
	push parameter4
	push parameter3
	push parameter2
	push parameter1
	push commandCode
	push PCIFunction
	push PCIDevice
	push PCIBus
	call handlerAddress


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef commandCode
	%undef parameter1
	%undef parameter2
	%undef parameter3
	%undef parameter4
	%undef parameter5
	mov esp, ebp
	pop ebp
ret 36





section .text
PCIHandlerGet:
	; Returns the handler address for the specified PCI class and subclass
	;
	;  input:
	;	PCI Class
	;	PCI Subclass
	;
	;  output:
	;	EAX - Handler physical address

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIClass							dword [ebp + 8]
	%define PCISubclass							dword [ebp + 12]


	; calculate slot address (slotNumber = 256 * class + subclass)
	mov eax, PCIClass
	mov edx, 256
	mul edx
	add eax, PCISubclass

	; get slot address
	push eax
	push dword [tSystem.listPtrPCIHandlers]
	call LMElementAddressGet

	; return slot contents in eax
	mov eax, dword [esi]


	.Exit:
	%undef PCIClass
	%undef PCISubclass
	mov esp, ebp
	pop ebp
ret 8





section .text
PCIHandlerSet:
	; Sets the handler address for the specified PCI class and subclass
	;
	;  input:
	;	PCI Class
	;	PCI Subclass
	;	Handler physical address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIClass							dword [ebp + 8]
	%define PCISubclass							dword [ebp + 12]
	%define handlerPtr							dword [ebp + 16]


	; calculate slot address (slotNumber = 256 * class + subclass)
	mov eax, PCIClass
	mov edx, 256
	mul edx
	add eax, PCISubclass

	; get slot address
	push eax
	push dword [tSystem.listPtrPCIHandlers]
	call LMElementAddressGet

	; insert address into slot
	mov eax, handlerPtr
	mov dword [esi], eax


	.Exit:
	%undef PCIClass
	%undef PCISubclass
	%undef handlerPtr
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoClassGet:
	; Returns the class of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AL - Class

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x02
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	shr eax, 24


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoDeviceGet:
	; Returns the device ID of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AX - Device ID

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x00
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	shr eax, 16


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoProgIfGet:
	; Returns the program interface (ProgIf) of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AL - ProgIf

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x02
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	shr eax, 8
	and eax, 0x000000FF


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoRevisionGet:
	; Returns the revision of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AL - Revision

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x02
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	and eax, 0x000000FF


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoSubclassGet:
	; Returns the subclass of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AL - Subclass

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x02
	push PCIFunction
	push PCIDevice
	push PCIBus
	call PCIRegisterRead

	shr eax, 16
	and eax, 0x000000FF


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIInfoVendorGet:
	; Returns the vendor ID of the device at the PCI bus location specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;
	;  output:
	;	AX - Vendor ID

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]


	push 0x00
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call PCIRegisterRead

	and eax, 0x0000FFFF


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	mov esp, ebp
	pop ebp
ret 12





section .text
PCIRegisterRead:
	; Reads a 32-bit register value from the PCI target specified
	; Note: This function reads directly from the PCI bus, not from the shadowed PCI data in RAM
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;
	;  output:
	;	EAX - Register value

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define PCIRegister							dword [ebp + 20]


	; we start by building a value out of the bus, device, function and register values provided
	mov eax, 0x00000000							; clear the destination
	mov ebx, PCIBus								; load the PCI bus provided
	and ebx, 0x000000FF							; PCI busses are 8 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 5									; shift left 5 bits to get ready for the next section

	mov ebx, PCIDevice							; load the PCI device provided
	and ebx, 0x0000001F							; PCI devices are 5 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 3									; shift left 3 bits to get ready for the next section

	mov ebx, PCIFunction						; load the PCI function provided
	and ebx, 0x00000007							; PCI functions are 3 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 6									; shift left 6 bits to get ready for the next section

	mov ebx, PCIRegister						; load the PCI registers provided
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


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef PCIRegister
	mov esp, ebp
	pop ebp
ret 16





section .text
PCIRegisterReadAll:
	; Gets all info for the specified PCI device and fills it into the struct at the given address
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI info struct address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define PCIStructPtr						dword [ebp + 20]


	; set the number of reads we need to do
	mov ecx, 64

	; start the loop to copy all the info
	.ReadLoop:
		; adjust ecx to point to the correct PCI register
		dec ecx

		push ecx

		; get the register
		push ecx
		push PCIFunction
		push PCIDevice
		push PCIBus
		call PCIRegisterRead

		; restore ecx
		pop ecx

		; calculate the write address
		mov esi, PCIStructPtr
		mov edi, esi
		mov edx, ecx
		shl edx, 2
		add edi, edx

		; adjust ecx
		inc ecx

		; write the register to the struct
		mov [edi], eax

	loop .ReadLoop


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef PCIStructPtr
	mov esp, ebp
	pop ebp
ret 16





section .text
PCIRegisterWrite:
	; Writes a 32-bit value to the target PCI register specified
	;
	;  input:
	;	PCI Bus
	;	PCI Device
	;	PCI Function
	;	PCI Register
	;	Value to write
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define PCIBus								dword [ebp + 8]
	%define PCIDevice							dword [ebp + 12]
	%define PCIFunction							dword [ebp + 16]
	%define PCIRegister							dword [ebp + 20]
	%define registerValue						dword [ebp + 24]


	; we start by building a value out of the bus, device, function and register values provided
	mov eax, 0x00000000							; clear the destination
	mov ebx, PCIBus								; load the PCI bus provided
	and ebx, 0x000000FF							; PCI registers are 8 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 5									; shift left 5 bits to get ready for the next section

	mov ebx, PCIDevice							; load the PCI device provided
	and ebx, 0x0000001F							; PCI devices are 5 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 3									; shift left 3 bits to get ready for the next section

	mov ebx, PCIFunction						; load the PCI function provided
	and ebx, 0x00000007							; PCI functions are 3 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 6									; shift left 6 bits to get ready for the next section

	mov ebx, PCIRegister						; load the PCI registers provided
	and ebx, 0x0000003F							; PCI registers are 6 bits, so make sure it's in range
	or eax, ebx									; copy the bits into our destination
	shl eax, 2									; shift left 2 bits to finalize and align

	or eax, 0x80000000							; set bit 31 to enable configuration

	; write the value we just built to select the proper target
	mov dx, kPCIAddressPort
	out dx, eax

	; get the value to write from the stack
	mov eax, registerValue

	; write the data register
	mov dx, kPCIDataPort
	out dx, eax


	.Exit:
	%undef PCIBus
	%undef PCIDevice
	%undef PCIFunction
	%undef PCIRegister
	%undef registerValue
	mov esp, ebp
	pop ebp
ret 20
