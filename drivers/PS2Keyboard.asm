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
PS2KeyboardInputHandler:
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


	; deal with spurious Acks
	cmp al, 0xfa
	jne .Continue
		cmp byte [tSystem.mousePacketByteCount], 0
		je .Exit
	.Continue:


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
