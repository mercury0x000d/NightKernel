; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; PS2 Controller.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.




; 32-bit function listing:
; PS2ControllerInit				Initializes the driver and controller
; KeyGet						Returns the oldest key in the key buffer, or null if it's empty
; KeyWait						Waits until a key is pressed, then returns that key
; PS2ControllerCommand			Sends a command to the PS/2 Controller with proper wait states
; PS2ControllerPortTest			Tests the PS/2 port specified
; PS2ControllerWaitDataRead		Reads data from the PS/2 controller with a 16 tick timeout (1/16 of a second)
; PS2ControllerWaitDataWrite	Waits until the PS/2 controller is ready to accept data with a 16 tick timeout (1/16 of a second)
; PS2DeviceCommand				Sends a command to a PS/2 device with proper wait states
; PS2DeviceIdentify				Executes the PS/2 Identify command and returns the result
; PS2InitKeyboard				Initializes the PS/2 keyboard
; PS2InitMouse					Initializes the PS/2 mouse
; PS2InputHandlerDispatch		Chooses which device handler receives input given
; PS2InputHandlerKeyboard		Handles input from a PS/2 Keyboard
; PS2InputHandlerMouse			Handles input from a PS/2 Mouse
; PS2NewConnect					Handles identifying and initializing new connected devices
; PS2Port1InterruptHandler		Handles interrupts from PS/2 Controller Port 1
; PS2Port2InterruptHandler		Handles interrupts from PS/2 Controller Port 2
; PS2PortInitDevice				Initializes the device on the port specified
; PS2PortSendTo2				Tells the PS/2 Controller the next command goes to port 2 if necessary

global KeyGet, KeyWait

extern PrintIfConfigBits32, InterruptHandlerSet, PICIRQDisable, PICIRQEnable,\
		MemAllocate, TimerWait, PrintRegs32, PICIRQDisableAll, PICIRQEnableAll,\
		PICIntComplete
; globals
section .bss
kKeyBufferAddress								resd 1

section .data
kKeyBufferWrite									db 0x00
kKeyBufferRead									db 0x00



%include "globals.inc"

bits 32





section .text
PS2ControllerLegacyDriverHeader:
.signature$										db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05
.driverFlags									dd 10000000000000000000000000000001b





section .text
PS2ControllerInit:
	; Initializes the driver, controller, and any devices found on either port
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 2
	%define IRQFlags							byte [ebp - 1]
	%define configRegister						byte [ebp - 2]


	; announce ourselves!
	push .driverIntro$
	call PrintIfConfigBits32


	; init the IRQ flags - we use this in tracking which IRQs, if any, will remain disabled
	; they both start set, but will be cleared if the respective port fails its initial test
	mov IRQFlags, 00000011b

	; set up interrupt handlers for both ports
	push 0x8E
	push PS2Port1InterruptHandler
	push 0x08
	push 0x21
	call InterruptHandlerSet

	push 0x8E
	push PS2Port2InterruptHandler
	push 0x08
	push 0x2C
	call InterruptHandlerSet


	; disable IRQs for both ports to ensure setup isn't interrupted
	push dword 1
	call PICIRQDisable

	push dword 12
	call PICIRQDisable


	; disable both ports for now
	push dword 0
	push dword 0xAD
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout

	; no need to check if port 2 exists first - this will be ignored if it doesn't
	push dword 0
	push dword 0xA7
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; get controller configuration byte
	push dword 0
	push dword 0x20
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout

	; clear bits 0 (Port 1 interrupt), 1 (Port 2 interrupt), and 6 (Port 1 translation)
	and al, 10111100b

	; save the register since we'll need it again later
	mov configRegister, al

	; write controller configuration byte
	push eax
	push dword 0x60
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; perform controller test
	push dword 0
	push dword 0xAA
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout

	; check the test results
	cmp al, 0x55
	jne .errorTestFail


	; since apparently the self test we just did can reset some controllers, we need to restore
	; the controller configuration byte again, just in case
	mov al, configRegister
	push eax
	push dword 0x60
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; test port 1
	push .port1Probing$
	call PrintIfConfigBits32

	push dword 0
	push dword 1
	call PS2ControllerPortTest
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; print results
	call .EvaluateTestResult


	; test port 2
	push .port2Probing$
	call PrintIfConfigBits32

	; send command - Test port 2
	push dword 0
	push dword 2
	call PS2ControllerPortTest
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; print results
	call .EvaluateTestResult


	; enable both ports
	push dword 0
	push dword 0xAE
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout

	push dword 0
	push dword 0xA8
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; get controller configuration byte (again, now that both ports are configured and enabled)
	push dword 0
	push dword 0x20
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; re-enable IRQs for both PS/2 ports (unless they failed their initial test!)
	; get controller configuration byte
	push dword 0
	push dword 0x20
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout

	; set bits 0 (Port 1 interrupt) and 1 (Port 2 interrupt)
	or al, 00000011b

	; write controller configuration byte
	push eax
	push dword 0x60
	call PS2ControllerCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .errorTimeout


	; reenable IRQs for both ports
	push dword 1
	call PICIRQEnable

	push dword 12
	call PICIRQEnable


	; allocate some RAM for the key buffer
	push 256
	push 1
	call MemAllocate
	pop ebx

	; check for error
	cmp ebx, 0
	je .errorTimeout
	
	; if we get here, we got a valid memory block
	mov [kKeyBufferAddress], ebx


	; And finally, send a reset command to each port. If the device responds, it will trigger the interrupt handler and
	; cause the device init code to be called to detect what it is and then set it up appropriately based on its type.

	; send reset to port 1
	push dword 0
	push dword 0xFF
	push dword 1
	call PS2DeviceCommand
	pop eax
	pop ebx

	; give the interrupt handler a tiny bit of time to do its job for port 1
	push dword 16
	call TimerWait


	; send reset to port 2
	push dword 0
	push dword 0xFF
	push dword 2
	call PS2DeviceCommand
	pop eax
	pop ebx

	jmp .Done


	.errorTimeout:
		; dump registers
		call PrintRegs32

		; throw an error message
		push .errorTimeout$
		call PrintIfConfigBits32
	jmp .Done


	.errorTestFail:
		; dump registers
		call PrintRegs32

		; throw an error message
		push .errorTestFail$
		call PrintIfConfigBits32

	.Done:
	mov esp, ebp
	pop ebp
ret

.EvaluateTestResult:
	; evaluate the test result
	cmp al, 00
	jne .NotOK
		push .portTestOK$
		jmp .EvaluateDone
	.NotOK:

	cmp al, 01
	jne .Not01
		push .portTestError1$
		jmp .EvaluateDone
	.Not01:

	cmp al, 02
	jne .Not02
		push .portTestError2$
		jmp .EvaluateDone
	.Not02:

	cmp al, 03
	jne .Not03
		push .portTestError3$
		jmp .EvaluateDone
	.Not03:

	cmp al, 04
	jne .Not04
		push .portTestError4$
		jmp .EvaluateDone
	.Not04:

	; if we get here, the controller reported an error for which we have no definition
	push .portTestErrorUndefined$

	.EvaluateDone:
	call PrintIfConfigBits32
ret

section .data
.driverIntro$									db 'PS/2 Controller Driver, 2019 by Mercury0x0D', 0x00
.selfTestFailed$								db 'Self Test fail, aborting init', 0x00
.port1Probing$									db 'Probing port 1', 0x00
.port2Probing$									db 'Probing port 2', 0x00
.portTestError1$								db 'Clock line stuck low, port will be disabled', 0x00
.portTestError2$								db 'Clock line stuck high, port will be disabled', 0x00
.portTestError3$								db 'Data line stuck low, port will be disabled', 0x00
.portTestError4$								db 'Data line stuck high, port will be disabled', 0x00
.portTestErrorUndefined$						db 'Undefined error, port will be disabled', 0x00
.portTestOK$									db 'Port test OK', 0x00
.errorTimeout$									db 'A timeout occurred while accessing the controller. Setup aborted.', 0x00
.errorTestFail$									db 'The controller failed self testing. Setup aborted.', 0x00





section .text
KeyGet:
	; Returns the oldest key in the key buffer, or null if it's empty
	;
	;  input:
	;   dummy value
	;
	;  output:
	;   key pressed in lowest byte of 32-bit value

	push ebp
	mov ebp, esp

	mov eax, 0x00000000
	mov ecx, 0x00000000
	mov edx, 0x00000000

	; load the buffer positions
	mov cl, [kKeyBufferRead]
	mov dl, [kKeyBufferWrite]

	; if the read position is the same as the write position, the buffer is empty and we can exit
	cmp dl, cl
	je .done

	; calculate the read address into esi
	mov esi, [kKeyBufferAddress]
	add esi, ecx

	; get the byte to return into al
	mov byte al, [esi]

	; update the read position
	inc cl
	mov byte [kKeyBufferRead], cl

	.done:
	; push the data we got onto the stack and exit
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret





section .text
KeyWait:
	; Waits until a key is pressed, then returns that key
	;
	;  input:
	;   dummy value
	;
	;  output:
	;   key code

	push ebp
	mov ebp, esp


	.KeyLoop:
		push 0
		call KeyGet
		pop eax
		cmp al, 0x00
	je .KeyLoop


	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret





section .text
PS2ControllerCommand:
	; Sends a command to the PS/2 Controller with proper wait states
	;
	;  input:
	;	Command byte
	;	Data byte
	;
	;  output:
	;	Controller response (if any)
	;	Error code

	push ebp
	mov ebp, esp


	; wait until ready to write
	push dword 0
	call PS2ControllerWaitDataWrite
	pop eax
	cmp eax, 0
	jne .TimeoutWrite

	; send command
	mov eax, [ebp + 8]
	out 0x64, al


	; see if the command sent has anything to say in response
	cmp al, 0x20
	jne .Not20
		; if we get here, handle response for command 0x20 (Read controller configuration byte)
		call .StandardSingleByteRead
		mov [ebp + 8], eax
		jmp .Success
	.Not20:


	cmp al, 0x60
	jne .Not60
		; if we get here, handle response for command 0x60 (Write controller configuration byte)

		; wait until ready to write
		push dword 0
		call PS2ControllerWaitDataWrite
		pop eax
		cmp eax, 0
		jne .TimeoutWrite

		; write the data byte for this command
		mov eax, [ebp + 12]
		out 0x60, al

		jmp .Success
	.Not60:

	cmp al, 0xA9
	jne .NotA9
		; if we get here, handle response for command 0xA9 (Test Port 2)
		call .StandardSingleByteRead
		mov [ebp + 8], eax
		jmp .Success
	.NotA9:


	cmp al, 0xAA
	jne .NotAA
		; if we get here, handle response for command 0xAA (Test controller)
		call .StandardSingleByteRead
		mov [ebp + 8], eax
		jmp .Success
	.NotAA:

	cmp al, 0xAB
	jne .NotAB
		; if we get here, handle response for command 0xAB (Test Port 1)
		call .StandardSingleByteRead
		mov [ebp + 8], eax
		jmp .Success
	.NotAB:

	; If we get here, the command has been sent, and there's no special reply. Success!
	jmp .Success

	.NoAck:
	mov dword [ebp + 12], 0x0000FF00
	jmp .Done


	.TimeoutRead:
	mov dword [ebp + 12], 0x0000FF01
	jmp .Done


	.TimeoutWrite:
	mov dword [ebp + 12], 0x0000FF02

	.Success:
	; signify no error
	mov dword [ebp + 12], 0

	.Done:
	mov esp, ebp
	pop ebp
ret

.StandardSingleByteRead:
	; wait until ready to read
	push dword 0
	call PS2ControllerWaitDataRead
	pop eax
	cmp eax, 0
	jne .TimeoutRead

	; read a byte
	mov eax, 0x00000000
	in al, 0x60
ret





section .text
PS2ControllerPortTest:
	; Tests the PS/2 port specified
	;
	;  input:
	;	Port number
	;	Dummy value
	;
	;  output:
	;	Port status
	;	Error code

	push ebp
	mov ebp, esp


	mov eax, dword [ebp + 8]

	cmp eax, 1
	jne .Not1
		; if we get here, it was port 1
		mov ebx, 0xAB
		jmp .SendCommand
	.Not1:


	cmp eax, 2
	jne .Done
		; if we get here, it was port 2
		mov ebx, 0xA9


	.SendCommand:
	; send Test Port command
	push dword 0
	push dword ebx
	call PS2ControllerCommand
	pop dword [ebp + 8]
	pop dword [ebp + 12]


	.Done:
	mov esp, ebp
	pop ebp
ret





section .text
PS2ControllerWaitDataRead:
	; Reads data from the PS/2 controller with a 16 tick timeout (1/16 of a second)
	;
	;  input:
	;	dummy value
	;
	;  output:
	;	error code

	push ebp
	mov ebp, esp


	mov edx, dword [tSystem.ticksSinceBoot]
	.waitLoop:
		; wait until the controller is ready
		in al, 0x64
		and al, 00000001b
		cmp al, 0x01
		je .Done

		; if we get here, the controller isn't ready, so see if we've timed out
		mov ecx, dword [tSystem.ticksSinceBoot]
		sub ecx, edx
		cmp ecx, 16
	jb .waitLoop

	; if we get here, we've timed out
	mov dword [ebp + 8], 0x0000FF01


	.Done:
	mov esp, ebp
	pop ebp
ret





section .text
PS2ControllerWaitDataWrite:
	; Waits until the PS/2 controller is ready to accept data with a 16 tick timeout (1/16 of a second)
	;
	;  input:
	;	dummy value
	;
	;  output:
	;	error code

	push ebp
	mov ebp, esp


	mov edx, dword [tSystem.ticksSinceBoot]
	.waitLoop:
		; wait until the controller is ready
		in al, 0x64
		and al, 00000010b
		cmp al, 0x00
		je .Done

		; if we get here, the controller isn't ready, so see if we've timed out
		mov ecx, dword [tSystem.ticksSinceBoot]
		sub ecx, edx
		cmp ecx, 16
	jb .waitLoop

	; if we get here, we've timed out
	mov dword [ebp + 8], 0x0000FF02


	.Done:
	mov esp, ebp
	pop ebp
ret





section .text
PS2DeviceCommand:
	; Sends a command to a PS/2 device with proper wait states
	;
	;  input:
	;	Port number of the device to recieve the command
	;	Command byte
	;	Data byte
	;
	;  output:
	;	Device response (if any)
	;	Error code

	push ebp
	mov ebp, esp


	; select port 2 if necessary
	push dword [ebp + 8]
	call PS2PortSendTo2

	; wait until ready to write
	push dword 0
	call PS2ControllerWaitDataWrite
	pop eax
	cmp eax, 0
	jne .TimeoutWrite

	; send command
	mov eax, dword [ebp + 12]
	out 0x60, al


	; see if the command sent has anything to say in response
	cmp al, 0xED
	jne .NotED
		; if we get here, handle response for command 0xF0 (select code set)

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck

		push dword [ebp + 8]
		call PS2PortSendTo2

		; wait until ready to write
		push dword 0
		call PS2ControllerWaitDataWrite
		pop eax
		cmp eax, 0
		jne .TimeoutWrite

		; write the data byte for this command
		mov eax, [ebp + 16]
		out 0x60, al

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck

		jmp .Success
	.NotED:

	cmp al, 0xF0
	jne .NotF0
		; if we get here, handle response for command 0xF0 (select code set)

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck

		; wait until ready to write
		push dword 0
		call PS2ControllerWaitDataWrite
		pop eax
		cmp eax, 0
		jne .TimeoutWrite

		; write the data byte for this command
		push dword [ebp + 8]
		call PS2PortSendTo2
		mov eax, [ebp + 16]
		out 0x60, al

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck

		jmp .Success
	.NotF0:

	cmp al, 0xF2
	jne .NotF2
		; if we get here, handle response for command 0xF2 (Identify)
		call .StandardSingleByteRead
		mov dword [ebp + 12], eax
		jmp .Success
	.NotF2:

	cmp al, 0xF3
	jne .NotF3
		; if we get here, handle response for command 0xF3 (set sample rate)

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck


		; select port 2 if needed
		push dword [ebp + 8]
		call PS2PortSendTo2

		; wait until ready to write
		push dword 0
		call PS2ControllerWaitDataWrite
		pop eax
		cmp eax, 0
		jne .TimeoutWrite

		; write the data byte for this command
		mov eax, [ebp + 16]
		out 0x60, al

		; wait until ready to read
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .TimeoutRead

		; check for ack
		in al, 0x60
		cmp al, 0xFA
		jne .NoAck

		jmp .Success
	.NotF3:

	cmp al, 0xF4
	jne .NotF4
		; if we get here, handle response for command 0xF4 (Enable data reporting)
		call .StandardSingleByteRead
		mov dword [ebp + 12], eax
		jmp .Success
	.NotF4:

	cmp al, 0xF5
	jne .NotF5
		; if we get here, handle response for command 0xF5 (Disable data reporting)
		call .StandardSingleByteRead
		mov dword [ebp + 12], eax
		jmp .Success
	.NotF5:

	cmp al, 0xF6
	jne .NotF6
		; if we get here, handle response for command 0xF6 (Use default settings)
		call .StandardSingleByteRead
		mov dword [ebp + 12], eax
		jmp .Success
	.NotF6:

	cmp al, 0xFF
	jne .NotFF
		; if we get here, handle response for command 0xFF (Reset)
		call .StandardSingleByteRead
		mov dword [ebp + 12], eax
		jmp .Success
	.NotFF:


	; If we get here, we've already written the command, and it wasn't a command which gives a reply.
	; Looks like all is well!
	jmp .Success

	.NoAck:
	; device failed to ack
	mov dword [ebp + 12], 0x00000000
	mov dword [ebp + 16], 0x0000FF00
	jmp .Done


	.TimeoutRead:
	; read timeout occurred
	mov dword [ebp + 12], 0x00000000
	mov dword [ebp + 16], 0x0000FF01
	jmp .Done


	.TimeoutWrite:
	; write timeout occurred
	mov dword [ebp + 12], 0x00000000
	mov dword [ebp + 16], 0x0000FF02

	.Success:
	; signify no error
	mov dword [ebp + 16], 0

	.Done:
	mov esp, ebp
	pop ebp
ret 4

.StandardSingleByteRead:
	; wait until ready to read
	push dword 0
	call PS2ControllerWaitDataRead
	pop eax
	cmp eax, 0
	jne .TimeoutRead

	; read a byte
	mov eax, 0x00000000
	in al, 0x60
ret





section .text
PS2DeviceIdentify:
	; Executes the PS/2 Identify command and returns the result
	;
	;  input:
	;	Port on which the device resides
	;	dummy value
	;
	;  output:
	;	device identification (with 0xFF for bytes that were not returned by the driver)
	;	error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define IDBytes								dword [ebp - 4]


	; init the IDBytes variable
	mov IDBytes, 0xFFFFFFFF


	; send Identify command
	push dword 0
	push dword 0xF2
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for ack
	cmp al, 0xFA
	jne .NoAck


	; this loop will read bytes out of the device until there aren't any more
	; we should get no more than 2 back, so it won't matter that any more than four will wrap around in the IDBytes variable
	.IDLoop:
		; make sure we're ready to read, and handle the result accordingly
		push dword 0
		call PS2ControllerWaitDataRead
		pop eax
		cmp eax, 0
		jne .IDLoopDone
	
		; get a byte of identification
		in al, 0x60

		; copy it to the IDBytes variable
		mov ebx, IDBytes
		shl ebx, 8
		mov bl, al
		mov IDBytes, ebx
	jmp .IDLoop


	.IDLoopDone:
		; all done, and no error!
		mov eax, IDBytes
		mov dword [ebp + 8], eax
		mov dword [ebp + 12], 0x00000000
	jmp .Done


	.NoAck:
		; the device failed to ack
		mov dword [ebp + 8], 0x00000000
		mov dword [ebp + 12], 0x0000FF00
	jmp .Done


	.TimeoutRead:
		; read timeout occurred
		mov dword [ebp + 8], 0x00000000
		mov dword [ebp + 12], 0x0000FF01
	jmp .Done


	.TimeoutWrite:
		; hmm... could this be a <WRITE TIMEOUT>?
		mov dword [ebp + 8], 0x00000000
		mov dword [ebp + 12], 0x0000FF02


	.Done:
	mov esp, ebp
	pop ebp
ret






section .text
PS2InitKeyboard:
	; Sets up the keyboard defaults
	;
	;  input:
	;   Port number on which the keyboard resides
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; disable data reporting
	push dword 0
	push dword 0xF5
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; set autorepeat delay and rate to fastest available
	push dword 0
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; set scan code set to 2
	push dword 2
	push dword 0xF0
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; illuminate all LEDs (remember, bit 7 must be zero!)
	push dword 0x0F
	push dword 0xED
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; enable data reporting
	push dword 0
	push dword 0xF4
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx


	.Done:
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2InitMouse:
	; Initializes the PS/2 mouse
	;
	;  input:
	;   Port number on which the mouse resides
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; start out with normal 3-byte packets for a normal 3-button mouse with no wheel
	mov byte [tSystem.mousePacketByteSize], 3
	mov byte [tSystem.mouseButtonCount], 3
	mov byte [tSystem.mouseWheelPresent], 0


	; disable data reporting
	push dword 0
	push dword 0xF5
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx


	; use default settings
	push dword 0
	push dword 0xF6
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx


	; attempt to promote mouse from 0x00 (Standard Mouse) to 0x03 (Wheel Mouse)
	push dword 200
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	push dword 100
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	push dword 80
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; get device ID
	push dword [ebp + 8]
	call PS2PortSendTo2
	push dword 0
	push dword 0
	call PS2DeviceIdentify
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; if the promotion didn't happen, then proceed as usual
	cmp ax, 0xFF03
	jne .NoMorePromotions


	; If we got here, this mouse is now in wheel mode! Update the mickey infos.
	mov byte [tSystem.mousePacketByteSize], 4
	mov byte [tSystem.mouseWheelPresent], 1

	call .UpdateDeviceID


	; Let's push our luck even more!
	; Attempt to promote mouse from 0x03 (Wheel Mouse) to 0x04 (5-Button Mouse)
	push dword 200
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	push dword 200
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	push dword 80
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; get device ID
	push dword [ebp + 8]
	call PS2PortSendTo2
	push dword 0
	push dword 0
	call PS2DeviceIdentify
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; see if the promotion happened
	cmp ax, 0xFF04
	jne .NoMorePromotions

	; if we got here, this mouse just got a promotion!
	mov byte [tSystem.mousePacketByteSize], 4
	mov byte [tSystem.mouseButtonCount], 5
	mov byte [tSystem.mouseWheelPresent], 1

	call .UpdateDeviceID


	.NoMorePromotions:
	; set the sample rate (for real this time)
	push dword 80
	push dword 0xF3
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; enable data reporting
	push dword 0
	push dword 0xF4
	push dword [ebp + 8]
	call PS2DeviceCommand
	pop eax
	pop ebx

	; check for error
	cmp ebx, 0
	jne .Done


	; limit mouse horizontally (I guess 640 pixels by default should work?)
	mov ax, 640
	mov word [tSystem.mouseXLimit], ax
	shr ax, 1
	mov word [tSystem.mouseX], ax


	; limit mouse vertically (480 pixels sounds good I suppose)
	mov ax, 480
	mov word [tSystem.mouseYLimit], ax
	shr ax, 1
	mov word [tSystem.mouseY], ax


	; init mouse wheel index
	mov word [tSystem.mouseZ], 0x8000


	; clear the mouse packet data
	mov byte [tSystem.mousePacketByteCount], 0
	mov byte [tSystem.mousePacketByte0], 0
	mov byte [tSystem.mousePacketByte1], 0
	mov byte [tSystem.mousePacketByte2], 0
	mov byte [tSystem.mousePacketByte3], 0


	.Done:
	mov esp, ebp
	pop ebp
ret 4

.UpdateDeviceID:
	cmp dword [ebp + 8], 1
	jne .NotPort1
		mov word [tSystem.PS2ControllerDeviceID1], ax
	.NotPort1:

	cmp dword [ebp + 8], 2
	jne .NotPort2
		mov word [tSystem.PS2ControllerDeviceID2], ax
	.NotPort2:
ret





section .text
PS2InputHandlerDispatch:
	; Chooses which device handler receives input given
	;
	;  input:
	;	PS/2 Device ID
	;	Data to be passed to the input handler
	;
	;  output:
	;	n/a


	push ebp
	mov ebp, esp


	; load the device ID
	mov eax, dword [ebp + 8]


	; load the data
	push dword [ebp + 12]


	cmp ax, 0xFFFF
	jne .NotFFFF
		call PS2InputHandlerKeyboard
		jmp .Done
	.NotFFFF:

	cmp ax, 0xFF00
	jne .NotFF00
		call PS2InputHandlerMouse
		jmp .Done
	.NotFF00:

	cmp ax, 0xFF03
	jne .NotFF03
		call PS2InputHandlerMouse
		jmp .Done
	.NotFF03:

	cmp ax, 0xFF04
	jne .NotFF04
		call PS2InputHandlerMouse
		jmp .Done
	.NotFF04:

	cmp ax, 0xAB41
	jne .NotAB41
		call PS2InputHandlerKeyboard
		jmp .Done
	.NotAB41:

	cmp ax, 0xABC1
	jne .NotABC1
		call PS2InputHandlerKeyboard
		jmp .Done
	.NotABC1:

	cmp ax, 0xAB83
	jne .Done
		call PS2InputHandlerKeyboard

	.Done:
	mov esp, ebp
	pop ebp
ret 8





section .text
PS2InputHandlerKeyboard:
	; Handles input from a PS/2 Keyboard
	;
	;  input:
	;	Input data
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get the input byte
	mov eax, dword [ebp + 8]


;--------------------------------------------------------------------------------
; temporary - only for use until we get a proper event queue in place
; if this is a break key, this lets it safely disappear from the input stream

; and when that happens, this may come in handy:
; https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes

cmp al, 0xF0
je .Adjust

cmp al, 0xE0
je .Done

cmp byte [.tempLastByte], 0xF0
jne .NotF0
	jmp .Adjust
.NotF0:
;--------------------------------------------------------------------------------


	; load the buffer position
	mov esi, [kKeyBufferAddress]
	mov edx, 0x00000000
	mov dl, [kKeyBufferWrite]
	add esi, edx

	; add the letter or symbol to the key buffer
	mov byte [esi], al

	; if the buffer isn't full, adjust the buffer pointer
	mov dh, [kKeyBufferRead]
	inc dl
	cmp dl, dh
	je .skipIncrement
		mov [kKeyBufferWrite], dl
		jmp .Done
	.skipIncrement:

;--------------------------------------------------------------------------------
.Adjust:
mov byte [.tempLastByte], al
;--------------------------------------------------------------------------------


	.Done:
	mov esp, ebp
	pop ebp
ret 4

section .data
.tempLastByte					db 0x00





section .text
PS2InputHandlerMouse:
	; Handles input from a PS/2 Mouse
	;
	;  input:
	;	Input data
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get the input byte
	mov eax, dword [ebp + 8]


	; add this byte to the mouse packet
	mov ebx, tSystem.mousePacketByte0
	mov ecx, 0x00000000
	mov cl, byte [tSystem.mousePacketByteCount]
	mov dl, byte [tSystem.mousePacketByteSize]
	add ebx, ecx
	mov byte [ebx], al

	; see if we have a full set of bytes and process them if so, skip to the end if not
	inc cl
	cmp cl, dl
	je .ProcessPacket
		inc byte [tSystem.mousePacketByteCount]
		jmp .Done
	.ProcessPacket:

	; if we get here, we have a whole packet
	mov byte [tSystem.mousePacketByteCount], 0


	; save edx, mask off the three main mouse buttons, restore edx
	mov byte dl, [tSystem.mousePacketByte0]
	and dl, 00000111b
	mov byte [tSystem.mouseButtons], dl

	; process the X axis
	mov eax, 0x00000000
	mov ebx, 0x00000000
	mov byte al, [tSystem.mousePacketByte1]
	mov word bx, [tSystem.mouseX]
	mov byte dl, [tSystem.mousePacketByte0]
	and dl, 00010000b
	cmp dl, 00010000b
	jne .mouseXPositive

	; movement was negative
	neg al
	sub ebx, eax

	; see if the mouse position would be beyond the left side of the screen, correct if necessary
	cmp ebx, 0x0000FFFF
	ja .mouseXNegativeAdjust

	jmp .mouseXDone


	.mouseXPositive:
		; movement was positive
		add ebx, eax

		; see if the mouse position would be beyond the right side of the screen, correct if necessary
		mov ax, [tSystem.mouseXLimit]
		cmp ebx, eax
	jae .mouseXPositiveAdjust


	.mouseXDone:
		mov word [tSystem.mouseX], bx

		; process the Y axis
		mov eax, 0x00000000
		mov ebx, 0x00000000
		mov byte al, [tSystem.mousePacketByte2]
		mov word bx, [tSystem.mouseY]
		mov byte dl, [tSystem.mousePacketByte0]
		and dl, 00100000b
		cmp dl, 00100000b
		jne .mouseYPositive

		; movement was negative (but we add to counteract the mouse's cartesian coordinate system)
		neg al
		add ebx, eax

		; see if the mouse position would be beyond the bottom of the screen, correct if necessary
		mov ax, [tSystem.mouseYLimit]
		cmp ebx, eax
		jae .mouseYPositiveAdjust
	jmp .mouseYDone
	
	.mouseYPositive:
		; movement was positive (but we subtract to counteract the mouse's cartesian coordinate system)
		sub ebx, eax
	
		; see if the mouse position would be beyond the top of the screen, correct if necessary
		cmp ebx, 0x0000FFFF
	ja .mouseYNegativeAdjust
	
	.mouseYDone:
	mov word [tSystem.mouseY], bx

	; if mouse is a 5-button, we process the extra buttons now
	mov byte al, [tSystem.mouseButtonCount]
	cmp al, 5
	jne .Not5Button
		; if we get here, we have a 5-button mouse
		; so let's mask off the wheel info and save it back to the packet byte for when we process the wheel later
		mov al, byte [tSystem.mousePacketByte3]
		mov bl, al
		and al, 0x0F

		; Some shifting magic to sign extend al. It works by copying bit 3 of al into cl then doing a series of
		; shift-and-copy operations to duplicate it across bits 4 through 7 of al.
		; This is done to adapt the shorter space allocated to the Z axis in 5-button mice (4 bits) to the wheel
		; handling code below which expects the traditional 8 bits.
		mov cl, al
		and cl, 00001000b
		shl cl, 1
		or al, cl
		shl cl, 1
		or al, cl
		shl cl, 1
		or al, cl
		shl cl, 1
		or al, cl
		mov byte [tSystem.mousePacketByte3], al

		; now we can handle buttons 4 and 5
		and bl, 0xF0
		mov al, byte [tSystem.mouseButtons]
		or al, bl
		mov byte [tSystem.mouseButtons], al
	.Not5Button:

	; see if we're using a wheel mouse and act accordingly
	mov al, byte [tSystem.mouseWheelPresent]
	cmp al, 0
	je .Done

	; if we get here, we have a wheel and need to process the Z axis
	mov eax, 0x00000000
	mov al, byte [tSystem.mousePacketByte3]
	mov bx, word [tSystem.mouseZ]
	mov cl, 0xF0
	and cl, al
	cmp cl, 0xF0
	jne .mouseZPositive

	; movement was negative
	neg al
	and al, 0x0F
	sub bx, ax
	jmp .mouseZDone

	.mouseZPositive:
	; movement was positive
	add bx, ax

	.mouseZDone:
	mov word [tSystem.mouseZ], bx

	.Done:
	mov esp, ebp
	pop ebp
ret 4

.mouseXNegativeAdjust:
	mov bx, 0x00000000
jmp .mouseXDone

.mouseXPositiveAdjust:
	mov bx, word [tSystem.mouseXLimit]
	dec bx
jmp .mouseXDone

.mouseYNegativeAdjust:
	mov bx, 0x00000000
jmp .mouseYDone

.mouseYPositiveAdjust:
	mov bx, word [tSystem.mouseYLimit]
	dec bx
jmp .mouseYDone





section .text
PS2NewConnect:
	; Handles identifying and initializing new connected devices
	;
	;  input:
	;	Port number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; This is a "just-in-case" since mice love to throw their IDs around...
	in al, 0x60


	; Here, we play with a bit of fire. We need to get data from the PS/2 Controller, but how do we do that when
	; everything it does requires a timeout in case it doesn't reply? The solution is to breifly disable all IRQs
	; except the timer itself, enable interrupts, then put everything back the way it was.
	call PICIRQDisableAll

	push dword 0
	call PICIRQEnable
	sti


	; now that we have a timer interrupt firing, we get and save the device ID
	push dword 0
	push dword [ebp + 8]
	call PS2DeviceIdentify
	pop eax
	pop ebx
	; We don't care about checking for errors here.
	; If it timed out, the device ID will be 0xFFFF anyway to indicate no device.


	; save the device ID to the appropriate spot
	cmp dword [ebp + 8], 1
	jne .Not1
		mov word [tSystem.PS2ControllerDeviceID1], ax
	.Not1:

	cmp dword [ebp + 8], 2
	jne .Not2
		mov word [tSystem.PS2ControllerDeviceID2], ax
	.Not2:


	; init the device
	push dword [ebp + 8]
	call PS2PortInitDevice
	pop eax


	; restore proper interrupt state
	cli
	call PICIRQEnableAll


	mov esp, ebp
	pop ebp
ret 4





section .text
PS2Port1InterruptHandler:
	; Handles interrupts from PS/2 Controller Port 1
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	pusha
	pushf


	mov eax, 0x00000000
	in al, 0x60


	; see if this is a test passed response, which means a new device was plugged in
	cmp al, 0xAA
	jne .NotNewDevice
		; We may have gotten a 0xAA as part of a mouse packet, too, so we have to check to make sure the last byte we got
		; was an 0xFA Ack. Only then should we handle initing a new device. This check doesn't apply to keyboards since
		; they will never send an 0xAA or an 0xFA as part of normal key code scanning.
		cmp byte [.lastByte], 0xFA
		jne .NotNewDevice

		; If we get here, a device just signaled its Self-Test has completed.
		; This means either we just booted and the device needs configured or the user hot-plugged a new PS/2 device.

		push dword 1
		call PS2NewConnect

		jmp .Done
	.NotNewDevice:


	; make a note of what this byte was for next time
	mov byte [.lastByte], al


	; handle the input we just got
	push eax
	push dword [tSystem.PS2ControllerDeviceID1]
	call PS2InputHandlerDispatch


	.Done:
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd

section .data
.lastByte						db 0x00





section .text
PS2Port2InterruptHandler:
	; Handles interrupts from PS/2 Controller Port 2
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	pusha
	pushf


	mov eax, 0x00000000
	in al, 0x60


	; see if this is a test passed response, which means a new device was plugged in
	cmp al, 0xAA
	jne .NotNewDevice
		; We may have gotten a 0xAA as part of a mouse packet, too, so we have to check to make sure the last byte we got
		; was an 0xFA Ack. Only then should we handle initing a new device. This check doesn't apply to keyboards since
		; they will never send an 0xAA or an 0xFA as part of normal key code scanning.
		cmp byte [.lastByte], 0xFA
		jne .NotNewDevice

		; If we get here, a device just signaled its Self-Test has completed.
		; This means either we just booted and the device needs configured or the user hot-plugged a new PS/2 device.

		push dword 2
		call PS2NewConnect

		jmp .Done
	.NotNewDevice:


	; make a note of what this byte was for next time
	mov byte [.lastByte], al


	; handle the input we just got
	push eax
	push dword [tSystem.PS2ControllerDeviceID2]
	call PS2InputHandlerDispatch


	.Done:
	call PICIntComplete

	popf
	popa

	mov esp, ebp
	pop ebp
iretd

section .data
.lastByte					db 0x00





section .text
PS2PortInitDevice:
	; Initializes the device on the port specified
	;
	;  input:
	;	Port number on which the device resides
	;
	;  output:
	;	error code

	push ebp
	mov ebp, esp


	; load the device ID into ax
	mov ax, [tSystem.PS2ControllerDeviceID1]
	cmp dword [ebp + 8], 2
	jne .NotPort2
		mov ax, [tSystem.PS2ControllerDeviceID2]
	.NotPort2:

	cmp ax, 0xFFFF
	jne .NotFFFF
		push dword [ebp + 8]
		call PS2InitKeyboard
		jmp .Done
	.NotFFFF:

	cmp ax, 0xFF00
	jne .NotFF00
		push dword [ebp + 8]
		call PS2InitMouse
		jmp .Done
	.NotFF00:

	cmp ax, 0xFF03
	jne .NotFF03
		push dword [ebp + 8]
		call PS2InitMouse
		jmp .Done
	.NotFF03:

	cmp ax, 0xFF04
	jne .NotFF04
		push dword [ebp + 8]
		call PS2InitMouse
		jmp .Done
	.NotFF04:

	cmp ax, 0xAB41
	jne .NotAB41
		push dword [ebp + 8]
		call PS2InitKeyboard
		jmp .Done
	.NotAB41:

	cmp ax, 0xABC1
	jne .NotABC1
		push dword [ebp + 8]
		call PS2InitKeyboard
		jmp .Done
	.NotABC1:

	cmp ax, 0xAB83
	jne .Done
		push dword [ebp + 8]
		call PS2InitKeyboard

.InitError:
	.Done:
	mov esp, ebp
	pop ebp
ret





section .text
PS2PortSendTo2:
	; Tells the PS/2 Controller the next command goes to port 2 if necessary
	;
	;  input:
	;	Port number being addressed
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	cmp dword [ebp + 8], 2
	jne .Done


	; If we get here, we're dealing with device 2. Let's tell the controller so.
	push dword 0
	push dword 0xD4
	call PS2ControllerCommand
	pop eax
	pop ebx


	.Done:
	mov esp, ebp
	pop ebp
ret 4
