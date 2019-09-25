; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; numbers.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 32





section .text
BCDToDecimal:
	; Converts a 32-bit BCD number to decimal
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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
CheckRange:
	; Checks that a value passed is in range
	;
	;  input:
	;	Value to be tested
	;	Lower range boundary
	;	Upper range boundary
	;
	;  output:
	;	AL - Result
	;		True - The value is in range
	;		False - The value is not in range

	push ebp
	mov ebp, esp

	; define input parameters
	%define testValue							dword [ebp + 8]
	%define lowerBound							dword [ebp + 12]
	%define upperBound							dword [ebp + 16]


	; assume success
	mov al, true

	; test against lower boundary
	mov ebx, testValue
	cmp ebx, lowerBound
	jb .Fail

	; test against upper boundary
	cmp ebx, upperBound
	ja .Fail

	jmp .Exit

	.Fail:
	mov al, false


	.Exit:
	mov esp, ebp
	pop ebp
ret
