; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; PS2Keyboard.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/PS2KeyboardDefines.inc"

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
PS2KeyboardInit:
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


	.Exit:
	%undef portNum
	mov esp, ebp
	pop ebp
ret 4





section .text
PS2KeyboardInputHandler:
	; Handles input from a PS/2 Keyboard
	;
	;  input:
	;	Port number
	;	Input data
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]
	%define inputByte							dword [ebp + 12]


	; get the input byte
	mov eax, inputByte


	; deal with spurious Acks
	cmp al, kCmdAcknowledged
	je .Exit


	cmp al, 0xF0
	jne .NotKeyup
		; If we get here, this was a key up. Set the flag and discard this byte. Don't clear the buffer yet since there's more to come.
		bts dword [.keyFlags], 0

		jmp .Exit
	.NotKeyup:


	; if we get here the byte needs added to the buffer
	mov ebx, [.buffer]
	shl ebx, 8
	mov bl, al
	mov [.buffer], ebx


	; if we're in the middle of a multi-byte key, exit so that we don't prematurely send them 
	cmp ebx, 0xE114
	je .Exit

	cmp ebx, 0xE07CE0
	je .Exit

	cmp ebx, 0xE012E0
	je .Exit

	cmp ebx, 0xE07C
	je .Exit

	cmp ebx, 0xE012
	je .Exit

	cmp ebx, 0xE1
	je .Exit

	cmp ebx, 0xE0
	je .Exit



	; if we get here, we have a full set of key press bytes... now, to handle them

	; first, see if this is something we can handle directly
	cmp dword [.keyFlags], 0
	jne .SkipModifierKeys
		cmp bl, 0x58
		jne .NotCapsLock
			; if we get here, Caps Lock was pressed
			push kLockCaps
			call ToggleLock
			jmp .KeyComplete
		.NotCapsLock:

		cmp bl, 0x77
		jne .NotNumLock
			; if we get here, Num Lock was pressed
			push kLockNum
			call ToggleLock
			jmp .KeyComplete
		.NotNumLock:

		cmp bl, 0x7E
		jne .NotScrollLock
			; if we get here, Scroll Lock was pressed
			push kLockScroll
			call ToggleLock
			jmp .KeyComplete
		.NotScrollLock:
	.SkipModifierKeys:


pusha
mov eax, [.keyFlags]
call PrintRegs32
popa



	.KeyComplete:
	; clear the buffer and flags
	mov dword [.buffer], 0
	mov dword [.keyFlags], 0

	jmp .Exit


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


	.Exit:
	%undef portNum
	%undef inputByte
	mov esp, ebp
	pop ebp
ret 8

section .data
.counter						dd 0x00000000
.keyFlags						dd 0x00000000
.buffer							dd 0x00000000





ToggleLock:
	; Toggles the keyboard lock state specified
	;
	;  input:
	;	Port number
	;	Lock bits
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define portNum								dword [ebp + 8]
	%define lockBits							dword [ebp + 12]


	; toggle the bits
	mov eax, lockBits
	btc dword [tSystem.configBits], eax

	push kCmdKeyboardSetLEDs
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit

	mov eax, [tSystem.configBits]
	and eax, 00000000000000000000000000000111b
	push eax
	push portNum
	call PS2DeviceWrite
	cmp edx, kErrNone
	jne .Exit


	.Exit:
	%undef inputByte
	mov esp, ebp
	pop ebp
ret 4
