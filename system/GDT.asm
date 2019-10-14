; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; GDT.asm is a part of the Night Kernel

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
GDTBuild:
	; Encodes the values passed into the format recognized by the CPU and stores the result at the address specified
	;
	;  input:
	;	Address at which to write encoded GDT element
	;	Base address
	;	Limit address
	;	Access
	;	Flags
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, dword [ebp + 8]

	; preserve edi
	mov esi, edi


	; encode base value
	; move bits 0:15
	mov eax, dword [ebp + 12]
	add edi, 2
	mov word [edi], ax

	; move bits 16:23
	add edi, 2
	ror eax, 16
	mov byte [edi], al

	; move bits 24:31
	add edi, 3
	ror eax, 8
	mov byte [edi], al


	; encode limit value
	; restore edi
	mov edi, esi
	mov eax, dword [ebp + 16]

	; move bits 0:15
	mov [edi], ax

	; move bits 16:19
	add edi, 6
	ror eax, 16
	mov byte [edi], al


	; encode access flags
	; correct edi
	dec edi
	mov eax, dword [ebp + 20]
	mov byte [edi], al

	; encode size flags
	; correct edi
	inc edi
	mov eax, dword [ebp + 24]
	shl eax, 4
	mov bl, [edi]
	or bl, al
	mov byte [edi], bl


	mov esp, ebp
	pop ebp
ret 20





section .text
GDTGetAccessFlags:
	; Returns the access flags from the GDT entry specifed
	;
	;  input:
	;	Address of GDT element to decode
	;
	;  output:
	;	EAX - Access flags

	push ebp
	mov ebp, esp


	mov esi, dword [ebp + 8]

	xor eax, eax
	add esi, 5
	mov al, byte [esi]


	mov esp, ebp
	pop ebp
ret 4





section .text
GDTGetBaseAddress:
	; Returns the base address from the GDT entry specifed
	;
	;  input:
	;	Address of GDT element to decode
	;
	;  output:
	;	EAX - Base address

	push ebp
	mov ebp, esp


	mov esi, dword [ebp + 8]

	; move bits 24:31 into eax
	xor eax, eax
	add esi, 7
	mov al, byte [esi]

	; move bits 16:23 into eax
	shl eax, 8
	sub esi, 3
	mov al, byte [esi]

	; move bits 0:15 into eax
	shl eax, 16
	sub esi, 2
	mov ax, word [esi]


	mov esp, ebp
	pop ebp
ret 4





section .text
GDTGetLimitAddress:
	;  input:
	; Returns the limit address from the GDT entry specifed
	;
	;	Address of GDT element to decode
	;
	;  output:
	;	EAX - Limit address

	push ebp
	mov ebp, esp


	mov esi, dword [ebp + 8]
	xor eax, eax

	; move bits 16:19 into eax
	add esi, 6
	mov al, byte [esi]
	and al, 0x0F

	; move bits 0:15 into eax
	shl eax, 16
	sub esi, 6
	mov ax, word [esi]


	mov esp, ebp
	pop ebp
ret 4





section .text
GDTGetSizeFlags:
	; Returns the size flags from the GDT entry specifed
	;
	;  input:
	;	Address of GDT element to decode
	;
	;  output:
	;	EAX - Size flags

	push ebp
	mov ebp, esp


	mov esi, dword [ebp + 8]

	xor eax, eax
	add esi, 6
	mov al, byte [esi]
	shr eax, 4


	mov esp, ebp
	pop ebp
ret 4





section .text
GDTSetAccessFlags:
	; Sets the access flags to the GDT entry specifed
	;
	;  input:
	;	Address at which to write encoded GDT element
	;	Access flags
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	mov edi, dword [ebp + 8]
	mov eax, dword [ebp + 12]

	add edi, 5
	mov byte [edi], al


	mov esp, ebp
	pop ebp
ret 8





section .text
GDTSetBaseAddress:
	; Sets the base address to the GDT entry specifed
	;
	;  input:
	;	Address at which to write encoded GDT element
	;	Base address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, dword [ebp + 8]
	mov eax, dword [ebp + 12]


	; move bits 0:15
	add edi, 2
	mov word [edi], ax


	; move bits 16:23
	add edi, 2
	ror eax, 16
	mov byte [edi], al


	; move bits 24:31
	add edi, 3
	ror eax, 8
	mov byte [edi], al


	mov esp, ebp
	pop ebp
ret 8





section .text
GDTSetLimitAddress:
	; Sets the limit address to the GDT entry specifed
	;
	;  input:
	;	Address at which to write encoded GDT element
	;	Limit address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	mov edi, dword [ebp + 8]
	mov eax, dword [ebp + 12]


	; move bits 0:15
	mov word [edi], ax


	; move bits 16:19
	add edi, 6
	ror eax, 16
	mov byte [edi], al


	mov esp, ebp
	pop ebp
ret 8





section .text
GDTSetSizeFlags:
	; Sets the size flags to the GDT entry specifed
	;
	;  input:
	;	Address at which to write encoded GDT element
	;	Size flags
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, dword [ebp + 8]
	mov eax, dword [ebp + 12]

	; encode size flags
	add edi, 6
	shl eax, 4
	mov bl, byte [edi]
	or bl, al
	mov byte [edi], bl


	mov esp, ebp
	pop ebp
ret 8
