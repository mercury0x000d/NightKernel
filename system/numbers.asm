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





%include "include/numbers.def"

%include "include/boolean.inc"





bits 16





section .text
QuadAdd16:
	; Adds two quadwords in real mode
	;
	;  input:
	;	Pointer to input QWord
	;	Pointer to output QWord
	;
	;  output:
	;	n/a
	;
	; Note: This 16-bit function takes doubleword pointers (not word) as input

	push bp
	mov bp, sp

	; define input parameters
	%define inPtr								dword [ebp + 4]
	%define outPtr								dword [ebp + 8]


	; add lower 32 bits first
	mov esi, inPtr
	mov edi, outPtr
	mov eax, [esi]
	add eax, [edi]

	; adjust pointers
	; an unrolled loop of INCs is used here because using a simple ADD may disrupt the flags register, and 
	; using a PUSHF / POPF combo is just sloppy in my opinion
	inc esi
	inc esi
	inc esi
	inc esi
	inc edi
	inc edi
	inc edi
	inc edi

	; now add upper 32 bits
	mov ebx, [esi]
	adc ebx, [edi]

	; write the values back to memory
	mov esi, outPtr
	mov [esi], eax
	add esi, 4
	mov [esi], ebx


	.Exit:
	%undef inPtr
	%undef outPtr
	mov sp, bp
	pop bp
ret 8





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


	.Exit:
	%undef accumulatedValue
	%undef magnitude
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
	%undef testValue
	%undef lowerBound
	%undef upperBound
	mov esp, ebp
	pop ebp
ret






section .text
QuadAdd:
	; Adds two quadwords
	;
	;  input:
	;	Pointer to input QWord
	;	Pointer to output QWord
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define inPtr								dword [ebp + 8]
	%define outPtr								dword [ebp + 12]


	; add lower 32 bits first
	mov esi, inPtr
	mov edi, outPtr
	mov eax, [esi]
	add eax, [edi]

	; adjust pointers
	; an unrolled loop of INCs is used here because using a simple ADD may disrupt the flags register, and 
	; using a PUSHF / POPF combo is just sloppy in my opinion
	inc esi
	inc esi
	inc esi
	inc esi
	inc edi
	inc edi
	inc edi
	inc edi

	; now add upper 32 bits
	mov ebx, [esi]
	adc ebx, [edi]

	; write the values back to memory
	mov esi, outPtr
	mov [esi], eax
	add esi, 4
	mov [esi], ebx


	.Exit:
	%undef inPtr
	%undef outPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
QuadShiftLeft:
	; Shifts a quadword left by the specified number of places
	;
	;  input:
	;	Pointer to QWord
	;	Number of places to shift
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define inPtr								dword [ebp + 8]
	%define shiftPlaces							dword [ebp + 12]


	; prep the registers
	mov esi, inPtr
	mov eax, [esi]
	add esi, 4
	mov ebx, [esi]
	mov ecx, shiftPlaces

	; if the number of places to shift is 64 or more, then we can just zero the value and leave
	cmp cl, 64
	jb .DoShift
		mov eax, 0
		mov ebx, 0
		jmp .Done
	.DoShift:

	; depending on exactly what needs shifted, we can optimize here
	cmp cl, 32
	jb .FullShift
		; if we get here, only one dword will need altered and the other can simply be zeroed
		mov ebx, eax
		mov eax, 0
		and cl, 31
		shl ebx, cl
		jmp .Done
	.FullShift:

	; if we get here, both the high and low dwords will need altered
	shld ebx, eax, cl
	shl eax, cl

	.Done:
	; write the value back to memory
	mov esi, inPtr
	mov [esi], eax
	add esi, 4
	mov [esi], ebx


	.Exit:
	%undef inPtr
	%undef shiftPlaces
	mov esp, ebp
	pop ebp
ret 8





section .text
QuadShiftRight:
	; Shifts a quadword right by the specified number of places
	;
	;  input:
	;	Pointer to QWord
	;	Number of places to shift
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define inPtr								dword [ebp + 8]
	%define shiftPlaces							dword [ebp + 12]


	; prep the registers
	mov esi, inPtr
	mov eax, [esi]
	add esi, 4
	mov ebx, [esi]
	mov ecx, shiftPlaces

	; if the number of places to shift is 64 or more, then we can just zero the value and leave
	cmp cl, 64
	jb .DoShift
		mov eax, 0
		mov ebx, 0
		jmp .Done
	.DoShift:

	; depending on exactly what needs shifted, we can optimize here
	cmp cl, 32
	jb .FullShift
		; if we get here, only one dword will need altered and the other can simply be zeroed
		mov eax, ebx
		shr ebx, 31
		and cl, 31
		shr eax, cl
		jmp .Done
	.FullShift:

	; if we get here, both the high and low dwords will need altered
	shrd eax, ebx, cl
	shr ebx, cl

	.Done:
	; write the value back to memory
	mov esi, inPtr
	mov [esi], eax
	add esi, 4
	mov [esi], ebx


	.Exit:
	%undef inPtr
	%undef shiftPlaces
	mov esp, ebp
	pop ebp
ret 8





section .text
Random:
	; Returns a random number using the XORShift method
	;
	;  input:
	;	Number limit
	;
	;  output:
	;	EAX - 32-bit random number between 0 and the number limit

	push ebp
	mov ebp, esp

	; define input parameters
	%define numLimit							dword [ebp + 8]


	mov ebx, numLimit

	; use good ol' XORShift to get a random
	mov eax, dword [.randomSeed]
	mov edx, eax
	shl eax, 13
	xor eax, edx
	mov edx, eax
	shr eax, 17
	xor eax, edx
	mov edx, eax
	shl eax, 5
	xor eax, edx
	mov dword [.randomSeed], eax

	; use some modulo to make sure the random is below the requested number
	mov edx, 0x00000000
	div ebx
	mov eax, edx


	.Exit:
	%undef numLimit
	mov esp, ebp
	pop ebp
ret 4

section .data
.randomSeed										dd 0x92D68CA2
