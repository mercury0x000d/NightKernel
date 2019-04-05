; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; misc.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 16-bit function listing:
; SetSystemAPM					Gets the APM interface version and saves results to the tSystem structure



; 32-bit function listing:
; BCDToDecimal					Converts a 32-bit BCD number to decimal
; TimerWait						Waits the specified number of ticks





bits 16





section .text
SetSystemAPM:
	; Gets the APM interface version and saves results to the tSystem structure
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov ax, 0x5300
	mov bx, 0x0000
	int 0x15

	cmp bx, 0x504D
	jne .skipped

	mov byte [tSystem.APMVersionMajor], ah
	mov byte [tSystem.APMVersionMinor], al
	mov word [tSystem.APMFeatures], cx

	.skipped:

	mov sp, bp
	pop bp
ret





bits 32





section .text
BCDToDecimal:
	; Converts a 32-bit BCD number to decimal
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	sub esp, 8
	%define accumulatedValue					dword [ebp - 4]
	%define magnitude							dword [ebp - 8]


	; init our "magnitude" value - it starts at 1 and multiplies by 10 every pass through the loop
	mov magnitude, 1

	; clear the accumulator variable
	mov accumulatedValue, 0

	; cycle through this 8 times since there are 8 possible digits in a 32-bit BCD number
	mov ecx, 8
	.DecodeLoop:
		; get the least significant BCD digit into bl
		mov ebx, dword [ebp + 8]
		and ebx, 0x0F

		; multiply bl by the current magnitude
		mov eax, magnitude
		mov edx, 0
		mul ebx

		; add the result to the accumulator
		add accumulatedValue, eax

		; quick multiply times 10 (shift to multiply by 8, then add two more)
		mov eax, magnitude
		shl magnitude, 3
		add magnitude, eax
		add magnitude, eax

		; rotate the next nibble into position
		ror dword [ebp + 8], 4
	loop .DecodeLoop

	mov eax, accumulatedValue
	mov [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret





section .text
TimerWait:
	; Waits the specified number of ticks
	;
	;  input:
	;   tick count
	;
	;  output:
	;   n/a
	
	push ebp
	mov ebp, esp


	; sample the current number of ticks since boot
	mov eax, [tSystem.ticksSinceBoot]
	.timerLoop:
		; get elamsed ticks as of right now
		mov ebx, [tSystem.ticksSinceBoot]
		
		; see if enough ticks have passed
		sub ebx, eax
		cmp ebx, dword [ebp + 8]
	jb .timerLoop


	mov esp, ebp
	pop ebp
ret 4
