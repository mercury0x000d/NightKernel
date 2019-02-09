; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; power.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 16-bit function listing:
; APMEnable						Activates the APM interface for all devices managed by the APM BIOS
; APMDisable					Disables the APM interface for all devices managed by the APM BIOS

; 32-bit function listing:
; APMShutdown					Shuts down the PC via the APM intereface



bits 16



APMEnable:
	; Activates the APM interface for all devices managed by the APM BIOS
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	;push bp
	;mov bp, sp

	;mov ax, 0x530D
	;mov bx, 0x0001
	;mov cx, 0x0001
	;int 0x15
	; add code to evaluate resulting code if there's an error

	;mov sp, bp
	;pop bp
ret



APMDisable:
	; Disables the APM interface for all devices managed by the APM BIOS
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov ax, 0x530D
	mov bx, 0x0001
	mov cx, 0x0000
	int 0x15
	; add code to evaluate resulting code if there's an error

	mov sp, bp
	pop bp
ret



bits 32



APMShutdown:
	; Shuts down the PC via the APM intereface
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov eax, cr0
	and eax, 11111110b
	mov cr0, eax

	mov ax, 0x5301
	mov bx, 0x0000
	int 0x15

	mov esp, ebp
	pop ebp
ret
