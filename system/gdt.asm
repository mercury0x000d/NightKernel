; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; gdt.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 32-bit function listing:
; GDTBuild						Encodes the values passed into the format recognized by the CPU
; GDTGetAccessFlags 			Returns the access flags from the GDT entry specifed
; GDTGetBaseAddress				Returns the base address from the GDT entry specifed
; GDTGetLimitAddress	 		Returns the limit address from the GDT entry specifed
; GDTGetSizeFlags 				Returns the size flags from the GDT entry specifed
; GDTInit						Builds and loads the kernel's GDT into GDTR
; GDTSetAccessFlags 			Sets the access flags to the GDT entry specifed
; GDTSetBaseAddress				Sets the base address to the GDT entry specifed
; GDTSetLimitAddress	 		Sets the limit address to the GDT entry specifed
; GDTSetSizeFlags 				Sets the size flags to the GDT entry specifed





bits 32





section .text
GDTBuild:
	; Encodes the values passed into the format recognized by the CPU and stores the result at the address specified
	;
	;  input:
	;	address at which to write encoded GDT element
	;   base address
	;	limit address
	;	access
	;	flags
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, [ebp + 8]


	; preserve edi
	mov esi, edi


	; encode base value
	; move bits 0:15
	mov eax, [ebp + 12]
	add edi, 2
	mov [edi], ax
	; move bits 16:23
	add edi, 2
	ror eax, 16
	mov [edi], al
	; move bits 24:31
	add edi, 3
	ror eax, 8
	mov [edi], al


	; encode limit value
	; restore edi
	mov edi, esi
	mov eax, [ebp + 16]
	; move bits 0:15
	mov [edi], ax
	; move bits 16:19
	add edi, 6
	ror eax, 16
	mov [edi], al


	; encode access flags
	; correct edi
	dec edi
	mov eax, [ebp + 20]
	mov [edi], al


	; encode size flags
	; correct edi
	inc edi
	mov eax, [ebp + 24]
	shl eax, 4
	mov bl, [edi]
	or bl, al
	mov [edi], bl


	; ...aaaaand exit!
	mov dword [ebp + 8], edx


	mov esp, ebp
	pop ebp
ret 20





section .text
GDTGetAccessFlags:
	; Returns the access flags from the GDT entry specifed
	;
	;  input:
	;   address of GDT element to decode
	;
	;  output:
	;	access flags

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]


	xor eax, eax
	add esi, 5
	mov al, byte [esi]


	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret

GDTGetBaseAddress:
	; Returns the base address from the GDT entry specifed
	;
	;  input:
	;   address of GDT element to decode
	;
	;  output:
	;   base address

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]


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


	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret

GDTGetLimitAddress:
	; Returns the limit address from the GDT entry specifed
	;
	;  input:
	;   address of GDT element to decode
	;
	;  output:
	;	limit address

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]
	xor eax, eax


	; move bits 16:19 into eax
	add esi, 6
	mov al, byte [esi]
	and al, 0x0F


	; move bits 0:15 into eax
	shl eax, 16
	sub esi, 6
	mov ax, word [esi]


	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret

GDTGetSizeFlags:
	; Returns the size flags from the GDT entry specifed
	;
	;  input:
	;   address of GDT element to decode
	;
	;  output:
	;	size flags

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]


	xor eax, eax
	add esi, 6
	mov al, byte [esi]
	shr eax, 4


	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret

GDTInit:
	; Builds and loads the kernel's GDT into GDTR
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret

GDTSetAccessFlags:
	; Sets the access flags to the GDT entry specifed
	;
	;  input:
	;	address at which to write encoded GDT element
	;	access flags
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	mov edi, [ebp + 8]
	mov eax, [ebp + 12]


	add edi, 5
	mov [edi], al


	mov esp, ebp
	pop ebp
ret 8

GDTSetBaseAddress:
	; Sets the base address to the GDT entry specifed
	;
	;  input:
	;	address at which to write encoded GDT element
	;   base address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, [ebp + 8]
	mov eax, [ebp + 12]


	; move bits 0:15
	add edi, 2
	mov [edi], ax


	; move bits 16:23
	add edi, 2
	ror eax, 16
	mov [edi], al


	; move bits 24:31
	add edi, 3
	ror eax, 8
	mov [edi], al


	mov esp, ebp
	pop ebp
ret 8

GDTSetLimitAddress:
	; Sets the limit address to the GDT entry specifed
	;
	;  input:
	;	address at which to write encoded GDT element
	;	limit address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	mov edi, [ebp + 8]
	mov eax, [ebp + 12]


	; move bits 0:15
	mov [edi], ax


	; move bits 16:19
	add edi, 6
	ror eax, 16
	mov [edi], al


	mov esp, ebp
	pop ebp
ret 8

GDTSetSizeFlags:
	; Sets the size flags to the GDT entry specifed
	;
	;  input:
	;	address at which to write encoded GDT element
	;	size flags
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; get destination pointer
	mov edi, [ebp + 8]
	mov eax, [ebp + 12]


	; encode size flags
	add edi, 6
	shl eax, 4
	mov bl, [edi]
	or bl, al
	mov [edi], bl


	mov esp, ebp
	pop ebp
ret 8

section .data
GDTStart:
; Null descriptor (Offset 0x00)
; this is normally all zeros, but it's also a great place to tuck away the GDT header info
dw GDTEnd - GDTStart - 1						; size of GDT
dd GDTStart										; base of GDT
dw 0x0000										; filler

; Kernel space code (Offset 0x08)
dw 0xffff										; limit low
dw 0x0000										; base low
db 0x00											; base middle
db 10011010b									; access
db 11001111b									; granularity
db 0x00											; base high

; Kernel space data (Offset 0x10)
dw 0xffff										; limit low
dw 0x0000										; base low
db 0x00											; base middle
db 10010010b									; access
db 11001111b									; granularity
db 0x00											; base high

; User Space code (Offset 0x18)
dw 0xffff										; limit low
dw 0x0000										; base low
db 0x00											; base middle
db 11111010b									; access
db 11001111b									; granularity
db 0x00											; base high

; User Space data (Offset 0x20)
dw 0xffff										; limit low
dw 0x0000										; base low
db 0x00											; base middle
db 11110010b									; access
db 11001111b									; granularity
db 0x00											; base high

GDTEnd:
