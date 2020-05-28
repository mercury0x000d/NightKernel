; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; misc.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/miscDefines.inc"

%include "include/globals.inc"
%include "include/memory.inc"
%include "include/screen.inc"
%include "include/strings.inc"





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
Fail:
	; Prints a fatal error message and hangs
	;
	;  input:
	;	Error string address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define error$								dword [ebp + 8]


	mov eax, 0x00000000

	push dword 0x00000000
	push dword 0x00000004

	mov al, byte [gCursorY]
	push dword eax

	mov al, byte [gCursorX]
	push dword eax

	push error$
	call Print32

	; and here we hang
	jmp $


	; why is this here? HE'S DEAD, JIM!
	.Exit:
	%undef error$
	mov esp, ebp
	pop ebp
ret 4





section .text
PrintCopyright:
	; Prints the copyright string
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a
	

	; print the kernel string
	push dword 0x00000000
	push dword 0x00000007
	mov al, byte [gCursorY]
	push eax
	mov al, byte [gCursorX]
	push eax
	push tSystem.copyright$
	call Print32

	mov byte [gCursorX], al
	mov byte [gCursorY], ah
ret





section .text
PrintVerison:
	; Prints the version string
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a
	

	; build and print the version string
	push 80
	push .scratch$
	push .versionFormat$
	call MemCopy

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.versionMajor]
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.versionMinor]
	push eax
	push .scratch$
	call StringTokenHexadecimal

	push dword 0
	mov eax, 0x00000000
	mov ax, word [tSystem.versionBuild]
	push eax
	push .scratch$
	call StringTokenDecimal

	push dword 0x00000000
	push dword 0x00000007
	mov al, byte [gCursorY]
	push eax
	mov al, byte [gCursorX]
	push eax
	push .scratch$
	call Print32

	mov byte [gCursorX], al
	mov byte [gCursorY], ah
ret

section .data
.versionFormat$									db 'Version ^.^, Build ^', 0x00

section .bss
.scratch$										resb 80





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
