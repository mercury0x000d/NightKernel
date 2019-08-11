; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; serial.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 32





section .text
SerialGetBaud:
	; Returns the current baud rate of the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - Baud rate

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]
	mov ebx, 0

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.divisorLatchLow							dw 0x0000
	.divisorLatchHigh							dw 0x0000
	.lineControl								dw 0x0000

	.setPort1:
	mov word [.divisorLatchLow], 0x03F8
	mov word [.divisorLatchHigh], 0x03F9
	mov word [.lineControl], 0x03FB
	jmp .selectDone

	.setPort2:
	mov word [.divisorLatchLow], 0x02F8
	mov word [.divisorLatchHigh], 0x02F9
	mov word [.lineControl], 0x02FB
	jmp .selectDone

	.setPort3:
	mov word [.divisorLatchLow], 0x03E8
	mov word [.divisorLatchHigh], 0x03E9
	mov word [.lineControl], 0x03EB
	jmp .selectDone

	.setPort4:
	mov word [.divisorLatchLow], 0x02E8
	mov word [.divisorLatchHigh], 0x02E9
	mov word [.lineControl], 0x02EB

	.selectDone:
	; set the DLAB bit of the LCR
	mov dx, word [.lineControl]
	in al, dx
	or al, 10000000b
	out dx, al

	; get the Divisor Latch high byte
	mov dx, word [.divisorLatchHigh]
	in al, dx
	mov bl, al
	shl bl, 8

	; get the Divisor Latch low byte
	mov dx, word [.divisorLatchLow]
	in al, dx
	mov bl, al

	; clear the DLAB bit of the LCR
	mov dx, word [.lineControl]
	in al, dx
	and al, 01111111b
	out dx, al

	; calculate baud rate from the divisor value currently in bx
	mov eax, 115200
	mov edx, 0
	div ebx


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetIER:
	; Returns the Interrupt Enable Register for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - IER

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03F9
	jmp .selectDone

	.setPort2:
	mov dx, 0x02F9
	jmp .selectDone

	.setPort3:
	mov dx, 0x03E9
	jmp .selectDone

	.setPort4:
	mov dx, 0x02E9

	.selectDone:
	; get the IER
	mov eax, 0x00000000
	in al, dx


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetIIR:
	; Returns the Interrupt Identification Register for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - IIR

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FA
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FA
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EA
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EA

	.selectDone:
	; get the IIR
	mov eax, 0x00000000
	in al, dx


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetLSR:
	; Returns the Line Status Register for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - LSR

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FD
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FD
	jmp .selectDone

	.setPort3:
	mov dx, 0x03ED
	jmp .selectDone

	.setPort4:
	mov dx, 0x02ED

	.selectDone:
	; get the LSR
	mov eax, 0x00000000
	in al, dx


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetMSR:
	; Returns the Modem Status Register for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - MSR

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FE
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FE
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EE
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EE

	.selectDone:
	; get the MSR
	mov eax, 0x00000000
	in al, dx


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetParity:
	; Returns the current parity setting of the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	Parity code
	;	 0 - No parity
	;	 1 - Odd parity
	;	 3 - Even parity
	;	 5 - Mark parity
	;	 7 - Space parity

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	; get the parity bits from the LCR
	mov eax, 0x00000000
	in al, dx
	and al, 00111000b
	shr al, 3


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetStopBits:
	; Returns the current number of stop bits for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	EAX - Number of stop bits (1 or 2)

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	; get the parity bits from the LCR
	mov eax, 0x00000000
	in al, dx
	and al, 00000100b
	shr al, 2
	inc al


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialGetWordSize:
	; Returns the current number of data word bits for the specified serial port
	;
	;  input:
	;	Port number
	;
	;  output:
	;	Number of data word bits (5 - 8)

	push ebp
	mov ebp, esp


	mov ecx, dword [ebp + 8]

	; get the port number off the stack and test it out
	pop eax
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	; get the word size from the LCR
	mov eax, 0x00000000
	in al, dx
	and al, 00000011b
	add al, 5


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
SerialPrintString:
	; Prints an ASCIIZ string as a series of characters to serial port 1
	;
	;  input:
	;	Address of string to print
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	mov ebx, dword [ebp + 8]

	mov dx, 0x03F8
	.serialLoop:
		mov al, [ebx]

		; have we reached the string end? if yes, exit the loop
		cmp al, 0x00
		je .end

		; we're still here, so let's send a character
		out dx, al

		mov ecx, dword [tSystem.ticksSinceBoot]
		.timerloop:
			mov eax, [tSystem.ticksSinceBoot]
			cmp al, cl
			jne .timerdone
		jmp .timerloop
		.timerdone:
		inc ebx
	jmp .serialLoop
	.end:

	; throw on a cr & lf
	mov al, 0x013
	out dx, al

	mov al, 0x010
	out dx, al


	mov esp, ebp
	pop ebp
ret 4





section .text
SerialSetBaud:
	; Sets the baud rate of the specified serial port
	;
	;  input:
	;	Port number
	;	Baud rate
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 6
	%define divisorLatchLow						word [ebp - 2]
	%define divisorLatchHigh					word [ebp - 4]
	%define lineControl							word [ebp - 6]


	; get the port number off the stack and test it out
	mov eax, [ebp + 8]
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov divisorLatchLow, 0x03F8
	mov divisorLatchHigh, 0x03F9
	mov lineControl, 0x03FB
	jmp .selectDone

	.setPort2:
	mov divisorLatchLow, 0x02F8
	mov divisorLatchHigh, 0x02F9
	mov lineControl, 0x02FB
	jmp .selectDone

	.setPort3:
	mov divisorLatchLow, 0x03E8
	mov divisorLatchHigh, 0x03E9
	mov lineControl, 0x03EB
	jmp .selectDone

	.setPort4:
	mov divisorLatchLow, 0x02E8
	mov divisorLatchHigh, 0x02E9
	mov lineControl, 0x02EB

	.selectDone:
	; set the DLAB bit of the LCR
	mov dx, lineControl
	in al, dx
	or al, 10000000b
	out dx, al

	; calculate the divisor value from the baud rate
	mov ebx, [ebp + 12]
	mov eax, 115200
	mov edx, 0
	div ebx

	; set the Divisor Latch low byte
	mov dx, divisorLatchLow
	out dx, al

	; set the Divisor Latch high byte
	mov dx, divisorLatchHigh
	shr ax, 8
	out dx, al

	; clear the DLAB bit of the LCR
	mov dx, lineControl
	in al, dx
	and al, 01111111b
	out dx, al

	; push the result code and return address
	mov edx, 0x00000000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
SerialSetIER:
	; Sets the Interrupt Enable Register for the specified serial port
	;
	;  input:
	;	Port number
	;	IER
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; get the port number off the stack and test it out
	mov eax, dword [ebp + 8]
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03F9
	jmp .selectDone

	.setPort2:
	mov dx, 0x02F9
	jmp .selectDone

	.setPort3:
	mov dx, 0x03E9
	jmp .selectDone

	.setPort4:
	mov dx, 0x02E9

	.selectDone:
	; set the IER
	mov eax, [ebp + 12]
	out dx, al

	; push the IER, result code and return address
	mov edx, 0x00000000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
SerialSetParity:
	; Sets the parity of the specified serial port
	;
	;  input:
	;	Port number
	;	Parity code
	;	 0 - No parity
	;	 1 - Odd parity
	;	 3 - Even parity
	;	 5 - Mark parity
	;	 7 - Space parity
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; get the port number off the stack and test it out
	mov eax, dword [ebp + 8]
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	mov ebx, [ebp + 12]
	shl bl, 3

	; get the LCR...
	in al, dx

	; ...modify it...
	and al, 11000111b
	or al, bl

	; ...and write it back
	out dx, al

	; if we get here, the result code is zero
	mov edx, 0x00000000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
SerialSetStopBits:
	; Sets the number of stop bits for the specified serial port
	;
	;  input:
	;	Port number
	;	Number of stop bits (1 or 2)
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; get the port number off the stack and test it out
	mov eax, dword [ebp + 8]
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	mov ebx, [ebp + 12]
	dec ebx
	shl ebx, 2

	; get the LCR...
	in al, dx

	; ...modify it...
	and al, 11111011b
	or al, bl

	; ...and write it back
	out dx, al

	; if we get here, the return code is zero
	mov edx, 0x00000000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
SerialSetWordSize:
	; Sets the number of data word bits for the specified serial port
	;
	;  input:
	;	Port number
	;	Number of data word bits
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; get the port number off the stack and test it out
	mov eax, dword [ebp + 8]
	cmp eax, 1
	jb .portValueTooLow
	cmp eax, 4
	ja .portValueTooHigh
	jmp .doneTesting

	.portValueTooLow:
	mov edx, 0x0000F001
	jmp .Exit

	.portValueTooHigh:
	mov edx, 0x0000F002
	jmp .Exit

	.doneTesting:
	; select the address of this serial port
	cmp eax, 4
	je .setPort4
	cmp eax, 3
	je .setPort3
	cmp eax, 2
	je .setPort2
	cmp eax, 1
	je .setPort1
	jmp .selectDone

	.setPort1:
	mov dx, 0x03FB
	jmp .selectDone

	.setPort2:
	mov dx, 0x02FB
	jmp .selectDone

	.setPort3:
	mov dx, 0x03EB
	jmp .selectDone

	.setPort4:
	mov dx, 0x02EB

	.selectDone:
	; get the word size from off the stack then adjust it
	mov ebx, [ebp + 12]
	sub ebx, 5

	; get the LCR...
	in al, dx

	; ...modify it...
	and al, 11111100b
	or al, bl

	; ...and write it back
	out dx, al

	; if we get here, the return code is zero
	mov edx, 0x00000000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8
