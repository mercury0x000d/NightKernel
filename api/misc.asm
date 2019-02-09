; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; api.asm is a part of the Night Kernel

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
; CRC32							Generates a CRC-32/JAMCRC checksum for the memory block specified
; SetSystemCPUID				Probes the CPU using CPUID instruction and saves results to the tSystem structure
; SetSystemCPUSpeed				Writes CPU speed info to the tSystem structure
; SetSystemRTC					Copies the RTC time and date into the tSystem structure
; TimerWait						Waits the specified number of ticks



; Miscellaneous routines which will eventually comprise the Night API



bits 16



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



SetSystemCPUID:
	; Probes the CPU using CPUID instruction and saves results to the tSystem structure
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

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
	jnae .done
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
	.done:

	mov esp, ebp
	pop ebp
ret



SetSystemCPUSpeed:
	; Writes CPU speed info to the tSystem structure
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; save the flags
	pushf

	; make sure interrupts are on so we have a timer to use
	sti
	
	; check the speed
	call CPUSpeedDetect
	pop eax
	mov [tSystem.delayValue], eax
	
	; restore the flags and exit
	popf

	mov esp, ebp
	pop ebp
ret



SetSystemRTC:
	; Copies the RTC time and date into the tSystem structure
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; wait until the status register tells us the RTC is busy
	mov al, 0x0A
	out 0x70, al
	.pollStatus1:
		in al, 0x71
		and al, 10000000b
		cmp al, 10000000b
		je .flagSet
	jmp .pollStatus1
	.flagSet:

	; wait until the status register tells us the RTC is not busy
	mov al, 0x0A
	out 0x70, al
	.pollStatus2:
		in al, 0x71
		and al, 10000000b
		cmp al, 00000000b
		je .flagClear
	jmp .pollStatus2
	.flagClear:

	; set binary format and 24 hour mode
	mov al, 0x0B
	out 0x70, al
	in al, 0x71
	or al, 00000110b
	mov bl, al
	mov al, 0x0B
	out 0x70, al
	mov al, bl
	out 0x71, al
	
	; get the century
	mov al, 0x32
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.century], al
	
	; get the year
	mov al, 0x09
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.year], al
	
	; get the month
	mov al, 0x08
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.month], al
	
	; get the day
	mov al, 0x07
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.day], al
	
	; get the hour
	mov al, 0x04
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.hours], al
	
	; get the minutes
	mov al, 0x02
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.minutes], al
	
	; get the seconds
	mov al, 0x00
	out 0x70, al
	mov eax, 0x00000000
	in al, 0x71
	mov byte [tSystem.seconds], al

	mov esp, ebp
	pop ebp
ret



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

	mov eax, [ebp + 8]
	
	mov ebx, 0x00000000

	.mainLoop:
		; set up the first pass of the inner delay loop
		mov dl, [tSystem.ticks]
		mov dh, dl

		.timerLoop:
			mov dl, [tSystem.ticks]
			cmp dl, dh
			jne .loopExit
		jmp .timerLoop
		.loopExit:
		inc ebx
		cmp eax, ebx
		je .done
	jmp .mainLoop
	.done:

	mov esp, ebp
	pop ebp
ret 4
