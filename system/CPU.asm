; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; CPU.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/CPUDefines.inc"

%include "include/globals.inc"





bits 32





section .text
CPUInit:
	; Configures CPU features
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; enable SSE extensions

	; disable cr0.em
	mov eax, cr0
	and eax, 11111111111111111111111111111011b

	; enable cr0.mp
	or eax, 00000000000000000000000000000010b
	mov cr0, eax

	; enable cr4.osfxsr
	mov eax, cr4
	or eax, 00000000000000000000001000000000b

	; enable cr4.osxmmexcpt
	or eax, 00000000000000000000010000000000b
	mov cr4, eax


	.Exit:
	mov esp, ebp
	pop ebp
ret





section .text
SetSystemCPUID:
	; Probes the CPU using CPUID instruction and saves results to the tSystem structure
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get vendor ID
	mov eax, 0x00000000
	cpuid
	mov esi, tSystem.CPUIDVendor$
	mov [tSystem.CPUIDLargestBasicQuery], eax
	mov [esi], ebx
	add esi, 4
	mov [esi], edx
	add esi, 4
	mov [esi], ecx


	; get processor brand string
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000004
	jnae .Exit
	mov [tSystem.CPUIDLargestExtendedQuery], eax

	mov eax, 0x80000002
	cpuid
	mov esi, tSystem.CPUIDBrand$
	mov [esi], eax
	add esi, 4
	mov [esi], ebx
	add esi, 4
	mov [esi], ecx
	add esi, 4
	mov [esi], edx
	add esi, 4

	mov eax, 0x80000003
	cpuid
	mov [esi], eax
	add esi, 4
	mov [esi], ebx
	add esi, 4
	mov [esi], ecx
	add esi, 4
	mov [esi], edx
	add esi, 4

	mov eax, 0x80000004
	cpuid
	mov [esi], eax
	add esi, 4
	mov [esi], ebx
	add esi, 4
	mov [esi], ecx
	add esi, 4
	mov [esi], edx


	.Exit:
	mov esp, ebp
	pop ebp
ret
