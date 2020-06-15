; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; events.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/eventsDefines.inc"

%include "include/debug.inc"
%include "include/errors.inc"
%include "include/globals.inc"
%include "include/hardware.inc"
%include "include/interrupts.inc"
%include "include/memory.inc"
%include "include/misc.inc"
%include "include/PIC.inc"
%include "include/screen.inc"





bits 32





section .text
EvtNew:
	; Inserts an event into the event queue(s)
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define commandByte							dword [ebp + 8]


	; do stuff


	.Exit:
	%undef commandByte
	mov esp, ebp
	pop ebp
ret
