; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; misc.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 16





section .text
SetSystemAPM:
	; Gets the APM interface version and saves results to the tSystem structure
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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
TimerWait:
	; Waits the specified number of ticks
	;
	;  input:
	;	Tick count
	;
	;  output:
	;	n/a
	
	push ebp
	mov ebp, esp


	; sample the current number of ticks since boot
	mov eax, [tSystem.ticksSinceBoot]
	.timerLoop:
		; get elapsed ticks as of right now
		mov ebx, [tSystem.ticksSinceBoot]
		
		; see if enough ticks have passed
		sub ebx, eax
		cmp ebx, dword [ebp + 8]
	jb .timerLoop


	mov esp, ebp
	pop ebp
ret 4
