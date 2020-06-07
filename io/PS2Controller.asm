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
%include "include/screen.inc"





bits 32





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
	call PS2ControllerWaitDataWrite
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
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit


	mov al, [tSystem.PS2Config]
	or al, (kCCBPort1Disable | kCCBPort2Disable)
	mov tempConfig, al

	; write the byte
	push eax
	call PS2ControllerWrite
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit

	; and finally, discard potential garbage
	call PS2BufferClear


	; As of now, port 2 should be disabled (bit 5, the kCCBPort2Disable bit, should be set).
	; If we get the config byte again and see it's not, we know there's no port 2 to begin with
	; and we can mark it for disable globally.
	push kCmdReadConfigByte
	call PS2ControllerCommand
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit

	call PS2ControllerRead
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit

	bt ax, kCCBPort2Disable
	jc .DualPortControllerTestDone
		; if we get here, this ain't no dual port controller. Mark port 2 for disable!
		and byte [tSystem.PS2Config], ~kCCBPort2Disable
	.DualPortControllerTestDone:


	; perform controller test
	push kCmdTestController
	call PS2ControllerCommand
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit

	; check the test results
	call PS2ControllerRead
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit
	cmp al, kControllerTestPass
	jne .Exit

	; HEY EVERYBODY! THE CONTROLLER'S OK!
	push .selfTestOK$
	call PrintIfConfigBits32

	; since apparently the self test we just did can reset some controllers, we need to restore
	; the controller configuration byte again, just in case
	; write controller configuration byte
	push kCmdWriteConfigByte
	call PS2ControllerCommand
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa
	cmp edx, kErrNone
	jne .Exit

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
	jne .Exit

	mov al, [tSystem.PS2Config]
	push eax
	call PS2ControllerWrite

	; take out the trash
	call PS2BufferClear


	; ; allocate some RAM for the key buffer
	; call MemAllocate
	; cmp edx, kErrNone
	; jne .Exit
	; mov [kKeyBufferAddress], eax


	; And finally, send a reset command to each port. If the device responds, it will trigger the interrupt handler and
	; cause the device init code to be called to detect what it is and then set it up appropriately based on its type.
	; This, my friend, is how we support hotplugging!



	; send reset to port 1
	call PS2ControllerWaitDataWrite
	cmp edx, kErrNone
	jne .Exit
	mov al, kCmdDeviceReset
	out kPS2DataPort, al
	push 1
	call PICIRQEnable


push 256
call TimerWait


	push 1
	call PICIRQDisable

	; take out the trash
	call PS2BufferClear

	; send reset to port 2
	push kCmdWritePort2InputPort
	call PS2ControllerCommand
	call PS2ControllerWaitDataWrite
	cmp edx, kErrNone
	jne .Exit
	mov al, kCmdDeviceReset
	out kPS2DataPort, al
	push 12
	call PICIRQEnable



call PICIRQEnableAll

; 	; ; send reset to port 1
; 	push kCmdDeviceReset
; 	push 1
; 	call PS2DeviceWrite




; should this perhaps only be executed if the port exists?
	; push kCmdDeviceReset
	; push 2
	; call PS2DeviceWrite


; jmp $



	; push 1
	; call PICIRQEnable




	jmp .Exit

	.Fail:
	; handle all that errory goodness


	.Exit:
pusha
mov eax, 0xAAAAAAAA
mov ebx, 0xAAAAAAAA
mov ecx, 0xAAAAAAAA
call PrintRegs32
popa

	%undef tempConfig
	mov esp, ebp
	pop ebp
ret

section .data
.selfTestFailed$								db 'Controller Test fail, aborting init', 0x00
.selfTestOK$									db 'Controller Test OK', 0x00
.errorTimeout$									db 'A timeout occurred while accessing the controller. Setup aborted.', 0x00
.errorTestFail$									db 'The controller failed self testing. Setup aborted.', 0x00





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
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2ControllerWaitDataRead:
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





section .text
PS2ControllerWaitDataWrite:
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






section .text
PS2InitKeyboard:
	; Initializes the PS/2 keyboard
	;
	;  input:
	;	Port number on which the keyboard resides
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]


	; set autorepeat delay and rate to fastest available
	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 0
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; set scan code set to 2
	push kCmdKeyboardGetSetScanCode
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 2
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; illuminate all LEDs (remember, bit 7 must be zero!)
	; debug - this is just a test that the keyboard is inited on real hardware - remove this for actual use
	push kCmdKeyboardSetLEDs
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 0x0F
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2InitMouse:
	; Initializes the PS/2 mouse
	;
	;  input:
	;	Port number on which the mouse resides
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]


	; start out with normal 3-byte packets for a normal 3-button mouse with no wheel
	mov byte [tSystem.mousePacketByteSize], 3
	mov byte [tSystem.mouseButtonCount], 3
	mov byte [tSystem.mouseWheelPresent], 0


	; use default settings
	push kCmdDeviceUseDefaultSettings
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; attempt to promote mouse from 0x00 (Standard Mouse) to 0x03 (Wheel Mouse)
	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 100
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 80
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; get device ID
	push portNum
	call PS2DeviceIdentify
	cmp edx, kErrNone
	jne .Exit


	; if the promotion didn't happen, then proceed as usual
	cmp ax, kDevMouseWheel
	jne .NoMorePromotions


	; If we got here, this mouse is now in wheel mode! Update the mickey infos.
	mov byte [tSystem.mousePacketByteSize], 4
	mov byte [tSystem.mouseWheelPresent], 1

	call .UpdateDeviceID


	; Let's push our luck even more!
	; Attempt to promote mouse from 0x03 (Wheel Mouse) to 0x04 (5-Button Mouse)
	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 80
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	; get device ID
	push portNum
	call PS2DeviceIdentify
	cmp edx, kErrNone
	jne .Exit


	; see if the promotion happened
	cmp ax, kDevMouse5Button
	jne .NoMorePromotions

	; if we got here, this mouse just got a promotion!
	mov byte [tSystem.mousePacketByteSize], 4
	mov byte [tSystem.mouseButtonCount], 5
	mov byte [tSystem.mouseWheelPresent], 1

	call .UpdateDeviceID


	.NoMorePromotions:
	; set the sample rate (for real this time)
	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push dword 80
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


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

	jmp .Exit


	.UpdateDeviceID:
		cmp portNum, 1
		jne .NotPort1
			mov word [tSystem.PS2Port1DeviceID], ax
		.NotPort1:

		cmp portNum, 2
		jne .NotPort2
			mov word [tSystem.PS2Port2DeviceID], ax
		.NotPort2:
	ret


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4





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
		call PS2InputHandlerMouse
		jmp .Exit
	.NotFF00:

	cmp ax, kDevMouseWheel
	jne .NotFF03
		push handlerData
		call PS2InputHandlerMouse
		jmp .Exit
	.NotFF03:

	cmp ax, kDevMouse5Button
	jne .NotFF04
		push handlerData
		call PS2InputHandlerMouse
		jmp .Exit
	.NotFF04:

	cmp ax, kDevKeyboardMFWithTranslation1
	jne .NotAB41
		push handlerData
		call PS2InputHandlerKeyboard
		jmp .Exit
	.NotAB41:

	cmp ax, kDevKeyboardMFWithTranslation2
	jne .NotABC1
		push handlerData
		call PS2InputHandlerKeyboard
		jmp .Exit
	.NotABC1:

	cmp ax, kDevKeyboardMF
	jne .Exit
		push handlerData
		call PS2InputHandlerKeyboard
	.NotAB83:


	.Exit:
	%undef deviceID
	%undef handlerData
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

	; define input parameters
	%define inputByte							dword [ebp + 8]


	; get the input byte
	mov eax, inputByte


;--------------------------------------------------------------------------------
; temporary - only for use until we get a proper event queue in place
; if this is a break key, this lets it safely disappear from the input stream

; and when that happens, this may come in handy:
; https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes

cmp al, 0xF0
je .Adjust

cmp al, 0xE0
je .Exit

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
		jmp .Exit
	.skipIncrement:

;--------------------------------------------------------------------------------
.Adjust:
mov byte [.tempLastByte], al
;--------------------------------------------------------------------------------


	.Exit:
	%undef inputByte
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

	; define input parameters
	%define inputByte							dword [ebp + 8]


	; get the input byte
	mov eax, inputByte
; pusha
; inc dword [.debuglog]
; mov edi, [.debuglog]
; mov byte [edi], al
; push 2
; push 0
; push 1
; push 1
; push 3
; push 0x900000
; call PrintRAM32
; popa

cmp al, 0xfa
jne .Continue
cmp byte [tSystem.mousePacketByteCount], 0
je .Exit

.Continue:
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
		jmp .Exit
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
	jmp .mouseXDone

	.mouseXNegativeAdjust:
		mov bx, 0x00000000
	jmp .mouseXDone

	.mouseXPositiveAdjust:
		mov bx, word [tSystem.mouseXLimit]
		dec bx
	jmp .mouseXDone

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

	.mouseYNegativeAdjust:
		mov bx, 0x00000000
	jmp .mouseYDone

	.mouseYPositiveAdjust:
		mov bx, word [tSystem.mouseYLimit]
		dec bx
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
	je .Exit

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


	.Exit:
	%undef inputByte
	mov esp, ebp
	pop ebp
ret 4

section .data
.debuglog						dd 0x00900020





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

; disable all interrupts except the timer tick interrupt
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

; disable all interrupts except the timer tick interrupt
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
		call PS2InitMouse
		jmp .Exit
	.NotFF00:

	cmp ax, kDevMouseWheel
	jne .NotFF03
		push portNum
		call PS2InitMouse
		jmp .Exit
	.NotFF03:

	cmp ax, kDevMouse5Button
	jne .NotFF04
		push portNum
		call PS2InitMouse
		jmp .Exit
	.NotFF04:

	cmp ax, kDevKeyboardMFWithTranslation1
	jne .NotAB41
		push portNum
		call PS2InitKeyboard
		jmp .Exit
	.NotAB41:

	cmp ax, kDevKeyboardMF
	jne .NotAB83
		push portNum
		call PS2InitKeyboard
	.NotAB83:

	cmp ax, kDevKeyboardMFWithTranslation2
	jne .NotABC1
		push portNum
		call PS2InitKeyboard
		jmp .Exit
	.NotABC1:


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4





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

	; define input parameters
	%define portNum								dword [ebp + 8]


	cmp portNum, 2
	jne .Exit


	; If we get here, we're dealing with device 2. Let's tell the controller so.
	push kCmdWritePort2InputPort
	call PS2ControllerCommand


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4




PS2BufferClear:
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
	call PS2ControllerWaitDataRead
	cmp edx, kErrNone
	jne .Exit

	; take a look! it's in a... register?
	in al, kPS2DataPort

	.Exit:
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
	call PS2ControllerWaitDataWrite
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
	push portNum
	call PS2PortSendTo2

	; wait until ready to write
	call PS2ControllerWaitDataWrite
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
	%undef dataByte
	mov esp, ebp
	pop ebp
ret 8







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
	or al, (kCCBPort1Disable | kCCBPort2Disable)
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
