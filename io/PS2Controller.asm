; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; PS2 Controller.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/PS2ControllerDefines.inc"

%include "include/debug.inc"
%include "include/errors.inc"
%include "include/globals.inc"
%include "include/hardware.inc"
%include "include/interrupts.inc"
%include "include/memory.inc"
%include "include/misc.inc"
%include "include/PIC.inc"
%include "include/PS2Keyboard.inc"
%include "include/PS2Mouse.inc"
%include "include/screen.inc"





bits 32





PS2BufferClear:
	; Clears the PS/2 buffer
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	mov edx, dword [tSystem.ticksSinceBoot]
	.waitLoop:
		in al, kPS2DataPort

		; see what the controller is doing
		in al, kPS2StatusRegister
		and al, 00000001b
		cmp al, 0x00
		je .Done


		; if we get here, the controller isn't ready, so see if we've timed out
		mov ecx, dword [tSystem.ticksSinceBoot]
		sub ecx, edx
		cmp ecx, kPS2TimeoutTicks
	jb .waitLoop

	; if we get here, the timeout has occurred
	mov edx, kErrPS2ControllerReadTimeout
	jmp .Exit

	.Done:
	mov edx, kErrNone


	.Exit:
ret





section .text
PS2ControllerCommand:
	; Sends a command to the PS/2 Controller with proper wait states
	;
	;  input:
	;	Command byte
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define commandByte							dword [ebp + 8]


	; wait until ready to write
	call PS2ControllerWriteWait
	cmp edx, kErrNone
	jne .Exit

	; send command
	mov eax, commandByte
	out kPS2CommandRegister, al


	.Exit:
	%undef commandByte
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2ControllerInit:
	; Initializes the controller and any attached devices
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 1
	%define tempConfig							byte [ebp - 1]

	; disable IRQs for both ports to ensure setup isn't interrupted
	call PICIRQDisableAll

	; reactivate the timer tick interrupt
	push 0
	call PICIRQEnable


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


	; empty ye olde bufferoonio
	call PS2BufferClear


	; set up the controller how we need it for now
	push kCmdWriteConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Timeout


	mov al, [tSystem.PS2Config]
	or al, (kCCBPort1Disable | kCCBPort2Disable)
	mov tempConfig, al

	; write the byte
	push eax
	call PS2ControllerWrite
	cmp edx, kErrNone
	jne .Timeout

	; and finally, discard potential garbage
	call PS2BufferClear


	; As of now, port 2 should be disabled (bit 5, the kCCBPort2Disable bit, should be set).
	; If we get the config byte again and see it's not, we know there's no port 2 to begin with
	; and we can mark it for disable globally.
	push kCmdReadConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Timeout

	call PS2ControllerRead
	cmp edx, kErrNone
	jne .Timeout

	bt ax, kCCBPort2Disable
	jc .DualPortControllerTestDone
		; if we get here, this ain't no dual port controller. Mark port 2 for disable!
		and byte [tSystem.PS2Config], ~kCCBPort2Disable
	.DualPortControllerTestDone:


	; perform controller test
	push kCmdTestController
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Timeout

	; check the test results
	call PS2ControllerRead
	cmp edx, kErrNone
	jne .Timeout
	cmp al, kControllerTestPass
	jne .TestFail

	; HEY EVERYBODY! THE CONTROLLER'S OK!
	push .selfTestOK$
	call PrintIfConfigBits32

	; since apparently the self test we just did can reset some controllers, we need to restore
	; the controller configuration byte again, just in case
	; write controller configuration byte
	push kCmdWriteConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Timeout

	mov al, tempConfig
	push eax
	call PS2ControllerWrite

	; take out the trash
	call PS2BufferClear


	; make sure the ports test ok, mark them globally for disable if not
	call PS2TestPorts


	; At this point we need to enable the ports once again before proceeding. If either port needs disabled
	; for whatever reason - either it doesn't exist in the first place, or it failed the port test - that
	; information is contained in our saved copy of the config byte, so in writing it back to the controller,
	; the ports will be instantly configured appropriately.
	push kCmdWriteConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Timeout

	mov al, [tSystem.PS2Config]
	push eax
	call PS2ControllerWrite

	; take out the trash
	call PS2BufferClear


	; allocate some RAM for the key buffer
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [kKeyBufferAddress], eax


	; And finally, send a reset command to each port. If the device responds, it will trigger the interrupt handler and
	; cause the device init code to be called to detect what it is and then set it up appropriately based on its type.
	; This, my friend, is how we support hotplugging!

	; send reset to port 1
	push kCmdDeviceReset
	push 1
	call PS2DeviceWrite

	push 1
	call PICIRQEnable


	push 256
	call TimerWait


	push 1
	call PICIRQDisable

	; take out the trash
	call PS2BufferClear

	; send reset to port 2
	; should this perhaps only be executed if the port exists?
	push kCmdDeviceReset
	push 2
	call PS2DeviceWrite

	push 12
	call PICIRQEnable

	push 256
	call TimerWait

	call PICIRQEnableAll

	jmp .Exit


	; handle all that errory goodness
	.TestFail:
	push .selfTestFailed$
	call PrintIfConfigBits32
	jmp .Exit

	.Timeout:
	push .errorTimeout$
	call PrintIfConfigBits32


	.Exit:
	%undef tempConfig
	mov esp, ebp
	pop ebp
ret

section .data
.selfTestFailed$								db 'Controller Test fail. Setup aborted.', 0x00
.selfTestOK$									db 'Controller Test OK', 0x00
.errorTimeout$									db 'A timeout occurred while accessing the controller. Setup aborted.', 0x00





section .text
PS2ControllerPortTest:
	; Tests the PS/2 port specified
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - Port status
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNumber							dword [ebp + 8]


	mov eax, portNumber

	cmp eax, 1
	jne .Not1
		; if we get here, it was port 1
		mov ebx, kCmdTestPort1
		jmp .SendCommand
	.Not1:


	cmp eax, 2
	jne .Done
		; if we get here, it was port 2
		mov ebx, kCmdTestPort2


	.SendCommand:
	; send Test Port command
	push ebx
	call PS2ControllerCommand

	; discard extra crap
	call PS2BufferClear


	.Done:
	%undef portNumber
	mov esp, ebp
	pop ebp
ret 4





PS2ControllerRead:
	; Reads a data byte from the PS/2 controller
	;
	;  input:
	;	n/a
	;
	;  output:
	;	AL - Data
	;	EDX - Error code


	; wait until ready to read
	call PS2ControllerReadWait
	cmp edx, kErrNone
	jne .Exit

	; Take a look, it's in a port! A data rainbow!
	in al, kPS2DataPort

	.Exit:
ret





section .text
PS2ControllerReadWait:
	; Waits until data is ready to be read from the PS/2 controller
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp


	mov edx, dword [tSystem.ticksSinceBoot]
	.waitLoop:
		; wait until the controller is ready
		in al, kPS2StatusRegister
		and al, 00000001b
		cmp al, 0x01
		je .Done

		; if we get here, the controller isn't ready, so see if we've timed out
		mov ecx, dword [tSystem.ticksSinceBoot]
		sub ecx, edx
		cmp ecx, kPS2TimeoutTicks
	jb .waitLoop

	; if we get here, the timeout has occurred
	mov edx, kErrPS2ControllerReadTimeout
	jmp .Exit

	.Done:
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret





PS2ControllerWrite:
	; Writes a data byte to the PS/2 controller
	;
	;  input:
	;	Data
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define dataByte							dword [ebp + 8]


	; wait until ready to write
	call PS2ControllerWriteWait
	cmp edx, kErrNone
	jne .Exit

	; and write!
	mov eax, dataByte
	out kPS2DataPort, al


	.Exit:
	%undef dataByte
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2ControllerWriteWait:
	; Waits until the PS/2 controller is ready to accept data
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp


	mov edx, dword [tSystem.ticksSinceBoot]
	.waitLoop:
		; wait until the controller is ready
		in al, kPS2StatusRegister
		and al, 00000010b
		cmp al, 0x00
		je .Done

		; if we get here, the controller isn't ready, so see if we've timed out
		mov ecx, dword [tSystem.ticksSinceBoot]
		sub ecx, edx
		cmp ecx, kPS2TimeoutTicks
	jb .waitLoop

	; if we get here, the timeout has occurred
	mov edx, kErrPS2ControllerWriteTimeout
	jmp .Exit

	.Done:
	mov edx, kErrNone

	.Exit:
	mov esp, ebp
	pop ebp
ret





PS2DeviceAnnounce:
	; Prints a message describing the PS/2 device specified
	;
	;  input:
	;	Device ID
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define deviceID							dword [ebp + 8]


	mov eax, deviceID

	cmp ax, kDevNone
	jne .NotNone
		push .devNone$
		jmp .Done
	.NotNone:

	cmp ax, kDevMouseStandard
	jne .NotStandardMouse
		push .devMouseStandard$
		jmp .Done
	.NotStandardMouse:

	cmp ax, kDevMouseWheel
	jne .NotWheelMouse
		push .devMouseWheel$
		jmp .Done
	.NotWheelMouse:

	cmp ax, kDevMouse5Button
	jne .NotMouse5Button
		push .devMouse5Button$
		jmp .Done
	.NotMouse5Button:

	cmp ax, kDevKeyboardMFWithTranslation1
	jne .NotKeyboardType1
		push .devKeyboardMFWithTranslation1$
		jmp .Done
	.NotKeyboardType1:

	cmp ax, kDevKeyboardMFWithTranslation2
	jne .NotKeyboardType2
		push .devKeyboardMFWithTranslation2$
		jmp .Done
	.NotKeyboardType2:

	cmp ax, kDevKeyboardMF
	jne .NotKeyboard
		push .devKeyboardMF$
		jmp .Done
	.NotKeyboard:

	push .devUnknown$

	.Done:
	call PrintIfConfigBits32


	.Exit:
	%undef deviceID
	mov esp, ebp
	pop ebp
ret 4

section .data
.devNone$										db 'No device found', 0x00
.devMouseStandard$								db 'Standard mouse found', 0x00
.devMouseWheel$									db 'Wheel mouse found', 0x00
.devMouse5Button$								db 'Five button mouse found', 0x00
.devKeyboardMFWithTranslation1$					db 'Multifunction keyboard type 1 (with translation) found', 0x00
.devKeyboardMFWithTranslation2$					db 'Multifunction keyboard type 2 (with translation) found', 0x00
.devKeyboardMF$									db 'Multifunction keyboard found', 0x00
.devUnknown$									db 'Unknown device found', 0x00





section .text
PS2DeviceIdentify:
	; Executes the PS/2 Identify command and returns the result
	;
	;  input:
	;	Port on which the device resides
	;
	;  output:
	;	EAX - Device identification (with 0xFF for bytes that were not returned by the driver)
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define IDBytes								dword [ebp - 4]


	; init the IDBytes variable
	mov IDBytes, 0xFFFFFFFF


	; send Identify command
	push kCmdGetDeviceID
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; a timeout here means the device just doesn't care about us - error!
	call PS2ControllerRead
	cmp edx, kErrNone
	jne .Exit

	; copy to IDBytes
	mov ebx, IDBytes
	shl ebx, 8
	mov bl, al
	mov IDBytes, ebx


	; if we timeout this time, no biggie - the device just didn't have so much to say
	call PS2ControllerRead
	cmp edx, kErrNone
	jne .Done

	; copy to IDBytes
	mov ebx, IDBytes
	shl ebx, 8
	mov bl, al
	mov IDBytes, ebx


	; some devices spit out extra crap here which we need to discard
	call PS2BufferClear

	.Done:
	mov eax, IDBytes
	mov edx, kErrNone


	.Exit:
	%undef portNum
	%undef IDBytes
	mov esp, ebp
	pop ebp
ret 4





PS2DeviceWrite:
	; Writes a data byte to a PS/2 device
	;
	;  input:
	;	Port number
	;	Data
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]
	%define dataByte							dword [ebp + 12]


	; select port 2 if necessary
	cmp portNum, 2
	jne .Not2
		; If we get here, we're dealing with device 2. Let's tell the controller so.
		push kCmdWritePort2InputPort
		call PS2ControllerCommand
	.Not2:


	; wait until ready to write
	call PS2ControllerWriteWait
	cmp edx, kErrNone
	jne .Exit

	; and write!
	mov eax, dataByte
	out kPS2DataPort, al

	call PS2ControllerRead
	cmp edx, kErrNone
	jne .Exit
	cmp al, kCmdAcknowledged
	jne .NoAck

	mov edx, kErrNone
	jmp .Exit


	.NoAck:
	; device failed to ack
	mov edx, kErrPS2AckFail


	.Exit:
	%undef portNum
	%undef dataByte
	mov esp, ebp
	pop ebp
ret 8





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

	; define input parameters
	%define deviceID							dword [ebp + 8]
	%define handlerData							dword [ebp + 12]


	; load the device ID
	mov eax, deviceID

	cmp ax, kDevMouseStandard
	jne .NotFF00
		push handlerData
		call PS2MouseInputHandler
		jmp .Exit
	.NotFF00:

	cmp ax, kDevMouseWheel
	jne .NotFF03
		push handlerData
		call PS2MouseInputHandler
		jmp .Exit
	.NotFF03:

	cmp ax, kDevMouse5Button
	jne .NotFF04
		push handlerData
		call PS2MouseInputHandler
		jmp .Exit
	.NotFF04:

	cmp ax, kDevKeyboardMFWithTranslation1
	jne .NotAB41
		push handlerData
		call PS2KeyboardInputHandler
		jmp .Exit
	.NotAB41:

	cmp ax, kDevKeyboardMFWithTranslation2
	jne .NotABC1
		push handlerData
		call PS2KeyboardInputHandler
		jmp .Exit
	.NotABC1:

	cmp ax, kDevKeyboardMF
	jne .Exit
		push handlerData
		call PS2KeyboardInputHandler
	.NotAB83:


	.Exit:
	%undef deviceID
	%undef handlerData
	mov esp, ebp
	pop ebp
ret 8





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

	; define input parameters
	%define portNum								dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define deviceID							dword [ebp - 4]


	; suspend port operation
	call PS2PortsDisable

	call PS2BufferClear

	; disable data reporting for both devices
	push kCmdDisableDataReporting
	push 1
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push kCmdDisableDataReporting
	push 2
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	call PS2BufferClear


	; now identify the device
	push portNum
	call PS2DeviceIdentify
	cmp edx, kErrNone
	jne .Exit
	mov deviceID, eax


	; save the device ID to the appropriate spot
	cmp portNum, 1
	jne .Not1
		mov word [tSystem.PS2Port1DeviceID], ax

		; init the device
		push portNum
		call PS2PortInitDevice

		mov ax, word [tSystem.PS2Port1DeviceID]
	.Not1:

	cmp portNum, 2
	jne .Not2
		mov word [tSystem.PS2Port2DeviceID], ax

		; init the device
		push portNum
		call PS2PortInitDevice

		mov ax, word [tSystem.PS2Port2DeviceID]
	.Not2:


	; shoutout what we found
	push eax
	call PS2DeviceAnnounce


	.Exit:
	; enable data reporting for both ports
	push kCmdEnableDataReporting
	push 1
	call PS2DeviceWrite

	push kCmdEnableDataReporting
	push 2
	call PS2DeviceWrite


	; restore port operation and proper interrupt state
	call PS2PortsEnable


	%undef portNum
	%undef deviceID
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
	push ds
	push es
	push 0x10
	push 0x10
	pop ds
	pop es

; disable all IRQs except the timer tick interrupt
call PICIRQDisableAll
push 0
call PICIRQEnable
sti

	mov eax, 0x00000000
	in al, kPS2DataPort


	; if we have a device ID for this port, that means there's an existing device there
	cmp word [tSystem.PS2Port1DeviceID], kDevNone
	je .NoDevice
		; the device is known and already set up, so let its handler handle this data
		push eax
		push dword [tSystem.PS2Port1DeviceID]
		call PS2InputHandlerDispatch

		jmp .Exit
	.NoDevice:

	; if we get here, there is currently no known device in this port, so let's see if we have enough to trigger device detection
	cmp al, kTestPass
	jne .Exit


	; if we got here, the device has signaled a Test Passed byte, so let's see what the thing is and set it up
	call PS2BufferClear
	push 1
	call PS2NewConnect


	.Exit:
cli
call PICIRQEnableAll
	call PICIntCompleteMaster


	pop es
	pop ds
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





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
	push ds
	push es
	push 0x10
	push 0x10
	pop ds
	pop es

; disable all IRQs except the timer tick interrupt
call PICIRQDisableAll
push 0
call PICIRQEnable
sti

	mov eax, 0x00000000
	in al, kPS2DataPort


	; if we have a device ID for this port, that means there's an existing device there
	cmp word [tSystem.PS2Port2DeviceID], kDevNone
	je .NoDevice
		; the device is known and already set up, so let its handler handle this data
		push eax
		push dword [tSystem.PS2Port2DeviceID]
		call PS2InputHandlerDispatch

		jmp .Exit
	.NoDevice:

	; if we get here, there is currently no known device in this port, so let's see if we have enough to trigger device detection
	cmp al, kTestPass
	jne .Exit


	; if we got here, the device has signaled a Test Passed byte, so let's see what the thing is and set it up
	call PS2BufferClear
	push 2
	call PS2NewConnect


	.Exit:
cli
call PICIRQEnableAll
	call PICIntCompleteSlave

	pop es
	pop ds
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
PS2PortInitDevice:
	; Initializes the device on the port specified
	;
	;  input:
	;	Port number on which the device resides
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]


	; load the device ID into ax
	mov ax, [tSystem.PS2Port1DeviceID]
	cmp portNum, 2
	jne .NotPort2
		mov ax, [tSystem.PS2Port2DeviceID]
	.NotPort2:

	cmp ax, kDevMouseStandard
	jne .NotFF00
		push portNum
		call PS2MouseInit
		jmp .Exit
	.NotFF00:

	cmp ax, kDevMouseWheel
	jne .NotFF03
		push portNum
		call PS2MouseInit
		jmp .Exit
	.NotFF03:

	cmp ax, kDevMouse5Button
	jne .NotFF04
		push portNum
		call PS2MouseInit
		jmp .Exit
	.NotFF04:

	cmp ax, kDevKeyboardMFWithTranslation1
	jne .NotAB41
		push portNum
		call PS2KeyboardInit
		jmp .Exit
	.NotAB41:

	cmp ax, kDevKeyboardMF
	jne .NotAB83
		push portNum
		call PS2KeyboardInit
	.NotAB83:

	cmp ax, kDevKeyboardMFWithTranslation2
	jne .NotABC1
		push portNum
		call PS2KeyboardInit
		jmp .Exit
	.NotABC1:


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4





PS2PortsDisable:
	; Disables IRQs and clocks for both PS/2 devices
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code


	push kCmdWriteConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Exit

	mov al, [tSystem.PS2Config]
	and al, ~(kCCBPort1IRQ | kCCBPort2IRQ)
	push eax
	call PS2ControllerWrite

	call PS2BufferClear


	.Exit:
ret





PS2PortsEnable:
	; Enables IRQs and clocks for both PS/2 devices
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code


	push kCmdWriteConfigByte
	call PS2ControllerCommand
	cmp edx, kErrNone
	jne .Exit

	mov al, [tSystem.PS2Config]
	push eax
	call PS2ControllerWrite
	cmp edx, kErrNone
	jne .Exit

	call PS2BufferClear

	.Exit:
ret





PS2TestPorts:
	; Tests all available PS/2 controller ports
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; test port 1 and print results
	push .port1Probing$
	call PrintIfConfigBits32

	push dword 1
	call PS2ControllerPortTest
	mov al, kCCBPort1Disable
	not al
	call .EvaluateTestResult

	; test port 2 (if it exists) and print results
	mov al, [tSystem.PS2Config]
	and al, kCCBPort2Disable
	jnz .Port2TestSkip
		push .port2Probing$
		call PrintIfConfigBits32

		push dword 2
		call PS2ControllerPortTest
		mov al, kCCBPort2Disable
		not al
		call .EvaluateTestResult
	.Port2TestSkip:

	jmp .Exit


	.EvaluateTestResult:
		; evaluate the test result
		cmp dl, kControllerPortTestPass
		jne .NotOK
			push .portTestOK$
			jmp .EvaluateDone
		.NotOK:

		cmp dl, kControllerPortClockLineStuckLow
		jne .Not01
			and byte [tSystem.PS2Config], al
			push .portTestError1$
			jmp .EvaluateDone
		.Not01:

		cmp dl, kControllerPortClockLineStuckHigh
		jne .Not02
			and byte [tSystem.PS2Config], al
			push .portTestError2$
			jmp .EvaluateDone
		.Not02:

		cmp dl, kControllerPortDataLineStuckLow
		jne .Not03
			and byte [tSystem.PS2Config], al
			push .portTestError3$
			jmp .EvaluateDone
		.Not03:

		cmp dl, kControllerPortDataLineStuckHigh
		jne .Not04
			and byte [tSystem.PS2Config], al
			push .portTestError4$
			jmp .EvaluateDone
		.Not04:

		; if we get here, the controller reported an error for which we have no definition
		and byte [tSystem.PS2Config], al
		push .portTestErrorUndefined$

		.EvaluateDone:
		call PrintIfConfigBits32
	ret


	.Exit:
	mov esp, ebp
	pop ebp
ret

section .data
.port1Probing$									db 'Testing port 1', 0x00
.port2Probing$									db 'Testing port 2', 0x00
.portTestError1$								db 'Clock line stuck low, port will be disabled', 0x00
.portTestError2$								db 'Clock line stuck high, port will be disabled', 0x00
.portTestError3$								db 'Data line stuck low, port will be disabled', 0x00
.portTestError4$								db 'Data line stuck high, port will be disabled', 0x00
.portTestErrorUndefined$						db 'Undefined error, port will be disabled', 0x00
.portTestOK$									db 'Port test OK', 0x00
