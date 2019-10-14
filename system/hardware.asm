; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; hardware.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/hardware defines.inc"





section .data
kKeyBufferWrite									db 0x00
kKeyBufferRead									db 0x00

section .bss
kKeyBufferAddress								resd 1





bits 32





section .text
KeyGet:
	; Returns the oldest key in the key buffer, or null if it's empty
	;
	;  input:
	;	n/a
	;
	;  output:
	;	AL - Key pressed

	push ebp
	mov ebp, esp

	mov eax, 0x00000000
	mov ecx, 0x00000000
	mov edx, 0x00000000

	; load the buffer positions
	mov cl, byte [kKeyBufferRead]
	mov dl, byte [kKeyBufferWrite]

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
	mov esp, ebp
	pop ebp
ret





section .text
KeyWait:
	; Waits until a key is pressed, then returns that key
	;
	;  input:
	;	n/a
	;
	;  output:
	;	AL - Key code

	push ebp
	mov ebp, esp


	.KeyLoop:
		call KeyGet
		cmp al, 0x00
	je .KeyLoop


	mov esp, ebp
	pop ebp
ret





section .text
PITInit:
	; Init the PIT for 256 ticks per second
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	mov ax, 1193180 / 256

	mov al, 00110110b
	out 0x43, al

	out 0x40, al
	xchg ah, al
	out 0x40, al


	mov esp, ebp
	pop ebp
ret





section .text
Reboot:
	; Performs a warm reboot of the PC
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; try the keyboard controller method for reboot
	mov dx, 0x92
	in al, dx
	or al, 00000001b
	out dx, al

	; if we get here, that didn't work
	; now we try the fast port write method
	mov al, 0xFF
	out 0xEF, al

	; hopefully never reach this, but if the reboots failed we can at least do a hard lockup...
	jmp $


	mov esp, ebp
	pop ebp
ret
