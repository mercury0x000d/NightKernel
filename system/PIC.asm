; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; PIC.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/PICDefines.inc"





bits 32





section .text
PICInit:
	; Initializes & remaps both PICs
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; set ICW1
	mov al, 0x11

	; set up PIC 1
	mov dx, kPIC1CmdPort
	out dx, al

	; set up PIC 2
	mov dx, kPIC2CmdPort
	out dx, al

	; set base interrupt to 0x20 (ICW2)
	mov al, 0x20
	mov dx, kPIC1DataPort
	out dx, al

	; set base interrupt to 0x28 (ICW2)
	mov al, 0x28
	mov dx, kPIC2DataPort
	out dx, al

	; set ICW3 to cascade PICs together
	mov al, 0x04
	mov dx, kPIC1DataPort
	out dx, al
	
	; set ICW3 to cascade PICs together
	mov al, 0x02
	mov dx, kPIC2DataPort
	out dx, al

	; set PIC 1 to x86 mode with ICW4
	mov al, 0x05
	mov dx, kPIC1DataPort
	out dx, al

	; set PIC 2 to x86 mode with ICW4
	mov al, 0x01
	mov dx, kPIC2DataPort
	out dx, al

	; zero the data register of PIC 1
	mov al, 0
	mov dx, kPIC1DataPort
	out dx, al

	; zero the data register of PIC 2
	mov dx, kPIC2DataPort
	out dx, al

	mov al, 0xFD
	mov dx, kPIC1DataPort
	out dx, al

	mov al, 0xFF
	mov dx, kPIC2DataPort
	out dx, al


	mov esp, ebp
	pop ebp
ret





section .text
PICIntComplete:
	; Tells both PICs the pending interrupt has been handled
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; Since it's called from within nearly all interrupt handlers, this routine has to be
	; fast and not overwrite any registers; here we save only what's about to be changed
	push eax
	push edx

	; set the interrupt complete bit
	mov al, 0x20

	; write bit to PIC 1
	mov dx, kPIC1CmdPort
	out dx, al

	; write bit to PIC 2
	mov dx, kPIC2CmdPort
	out dx, al

	; restore that stuff
	pop edx
	pop eax
ret





section .text
PICIRQDisable:
	; Disables the IRQ specified
	;
	;  input:
	;	IRQ number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get the IRQ number being specified
	mov eax, dword [ebp + 8]


	; make sure it's 15 or lower for sanity
	and al, 0x0F

	; copy al to cl for later use
	mov cl, al

	; determine if we should send this to PIC1 or PIC2
	cmp al, 8
	jb .PIC1

	; if we get here, it was for PIC 2
	sub cl, 8
	mov dx, kPIC2DataPort
	jmp .CalculuateBits

	.PIC1:
	mov dx, kPIC1DataPort


	.CalculuateBits:
	; calculate which bit will be set
	mov bl, 00000001b
	shl bl, cl


	; modify the Interrupt Mask Register
	in al, dx
	or al, bl

	
	; write the new register value
	out dx, al


	mov esp, ebp
	pop ebp
ret 4





section .text
PICIRQDisableAll:
	; Disables all IRQ lines across both PICs
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; disable IRQs
	mov al, 0xFF

	; write PIC 1
	mov dx, kPIC1DataPort
	out dx, al

	; write PIC 2
	mov dx, kPIC2DataPort
	out dx, al


	mov esp, ebp
	pop ebp
ret





section .text
PICIRQEnable:
	; Enables the IRQ specified
	;
	;  input:
	;	IRQ number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; get the IRQ number being specified
	mov eax, dword [ebp + 8]


	; make sure it's 15 or lower for sanity
	and al, 0x0F

	; copy al to cl for later use
	mov cl, al

	; determine if we should send this to PIC1 or PIC2
	cmp al, 8
	jb .PIC1

	; if we get here, it was for PIC 2
	sub cl, 8
	mov dx, kPIC2DataPort
	jmp .CalculuateBits

	.PIC1:
	mov dx, kPIC1DataPort


	.CalculuateBits:
	; calculate which bit will be set
	mov bl, 11111110b
	shl bl, cl


	; modify the Interrupt Mask Register
	in al, dx
	and al, bl

	
	; write the new register value
	out dx, al


	mov esp, ebp
	pop ebp
ret 4





section .text
PICIRQEnableAll:
	; Enables all IRQ lines across both PICs
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; set the byte
	mov al, 0x00

	; write to PIC 1
	mov dx, kPIC1DataPort
	out dx, al

	; write to PIC 2
	mov dx, kPIC2DataPort
	out dx, al


	mov esp, ebp
	pop ebp
ret





; IRQ mappings for future reference
; IRQ0		Timer
; IRQ1		PS/2 Port 1
; IRQ2		Cascade to second 8259A
; IRQ3		Serial port 2
; IRQ4		Serial port 1
; IRQ5		Parallel Port 2 (reserved on PS/2 systems)
; IRQ6		Diskette drive
; IRQ7		Parallel Port 1
; IRQ8		CMOS Real time clock
; IRQ9		CGA vertical retrace
; IRQ10		Reserved
; IRQ11		Reserved
; IRQ12		PS/2 Port 2 (reserved on AT systems)
; IRQ13		FPU
; IRQ14		Hard disk controller
; IRQ15		Reserved
