; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; PS2Mouse.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/PS2MouseDefines.inc"

%include "include/errors.inc"
%include "include/globals.inc"
%include "include/hardware.inc"
%include "include/interrupts.inc"
%include "include/memory.inc"
%include "include/misc.inc"
%include "include/PIC.inc"
%include "include/PS2Controller.inc"
%include "include/screen.inc"





bits 32





section .text
PS2MouseInit:
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

	push 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push 100
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push 80
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

	push 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push 200
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	push kCmdSetRate
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	push 80
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

	push 80
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
PS2MouseInputHandler:
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

	; deal with spurious Acks
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
