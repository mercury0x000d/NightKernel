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

%include "include/errors.inc"
%include "include/globals.inc"
%include "include/lists.inc"
%include "include/memory.inc"





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


	; check for SSE2 support
	push kCPU_sse2
	push tSystem.CPUFeatures
	call LMBitGet

	; skip enabling if the bit comes back clear
	jnc .SSEDone

	; skip enabling if there was any kind of error
	cmp edx, kErrNone
	jne .SSEDone
		; If we get here, this CPU supports SSE. Woohoo! Let's enable it so we can really fling the bits!

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
	.SSEDone:


	.Exit:
	mov esp, ebp
	pop ebp
ret





section .text
CPUProbe:
	; Probes features supported by the CPU and saves the results to the CPUFeatures bitfield
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
	mov [esi + 4], edx
	mov [esi + 8], ecx

	; init the bitfield
	push 192
	push tSystem.CPUFeatures
	call LMBitfieldInit

	; save feature flags
	; Writing data directly into the bitfield here bypasses the update of the setCount value that the List Manager would normally perform.
	; However... since we will never need that information... who cares?
	mov eax, 0x00000001
	mov ecx, 0
	cpuid
	mov esi, tSystem.CPUFeatures
	mov [esi + 16], ecx
	mov [esi + 20], edx

	; save extended feature flags
	mov eax, 0x00000007
	mov ecx, 0
	cpuid
	mov [esi + 24], ebx
	mov [esi + 28], ecx
	mov [esi + 32], edx

	mov eax, 0x00000007
	mov ecx, 1
	cpuid
	mov [esi + 36], eax


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
