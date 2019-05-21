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





; external functions
;extern MemSearchString

; external variables
;extern DriverSpaceStart, kDriverSignature$, DriverSpaceEnd





bits 32





section .text
DriverLegacyLoad:
	; Scans all drivers in the kernel's driver space and runs each legacy driver found
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; start a loop here which will cycle until the driver signature is no longer found
	mov esi, DriverSpaceStart

	.DriverDiscoveryLoop:
		; preserve the search address
		push esi

		; search for the signature of the first driver
		push kDriverSignature$
		push dword 16
		push esi
		call MemSearchString
		mov edi, eax

; corrects for a bug where MemSearchString returns the match address-1
inc edi

		; test the result
		cmp edi, 0
		jne .CheckLegacy
			; if we get here, we got a zero back... so no driver was found
			jmp .NextDriverIteration
		.CheckLegacy:

		; well, ok, we found some random driver... let's see if it's a legacy one
		
		; get edi pointing to the driver flags
		add edi, 16

		; see if we have a legacy driver
		mov eax, [edi]
		and eax, 10000000000000000000000000000000b
		cmp eax, 10000000000000000000000000000000b
		je .DriverIsLegacy
			; if we get here, it's not a legacy driver
			jmp .NextDriverIteration
		.DriverIsLegacy:

		; this driver should do the trick!
		; point edi to the start of the driver's init code
		add edi, 4

		; run the driver
		call edi

		.NextDriverIteration:
		; go back and scan again for another driver
		pop esi
		inc esi

		; exit if we're at the end of driver space
		cmp esi, DriverSpaceEnd
		je .DriverScanDone

	jmp .DriverDiscoveryLoop
	.DriverScanDone:
	; get rid of that extra copy of esi we saved earlier...
	pop esi

	; push the return value on the stack and exit
	mov dword [ebp + 16], edi


	mov esp, ebp
	pop ebp
ret





section .text
PITInit:
	; Init the PIT for 256 ticks per second
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

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
Random:
	; Returns a random number using the XORShift method
	;
	;  input:
	;   Number limit
	;
	;  output:
	;   EAX - 32-bit random number between 0 and the number limit

	push ebp
	mov ebp, esp


	mov ebx, dword [ebp + 8]

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


	mov esp, ebp
	pop ebp
ret 4

section .data
.randomSeed										dd 0x92D68CA2





section .text
Reboot:
	; Performs a warm reboot of the PC
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

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
