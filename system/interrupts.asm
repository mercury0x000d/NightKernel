; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; interrupts.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 32-bit function listing:
; CriticalError					Handles the UI portion of traps and exceptions
; IDTInit						Initializes the kernel IDT
; InterruptHandlerGet			Formats the passed data and writes it to the IDT in the slot specified
; InterruptHandlerSet			Formats the passed data and writes it to the IDT in the slot specified
; InterruptUnimplemented		A generic handler to run when an unimplemented interrupt is called
; ISRInitAll					Sets the interrupt handler addresses into the IDT





kUnsupportedInt$								db 'An unsupported interrupt has been called', 0x00
exceptionSelector								dd 0x00000000
exceptionAddress								dd 0x00000000
exceptionFlags									dd 0x00000000
kIDTPtr											dd 0x00000000





bits 32





section .text
CriticalError:
	; Handles the UI portion of traps and exceptions
	;
	;  input:
	;   address of error description string to print
	;
	;  output:
	;   n/a

	pop dword [.returnAddress]

	mov byte [backColor], 0x01
	mov byte [textColor], 0x07
	call ScreenClear32

	; clear the print string
	push dword 0
	push dword 256
	push kPrintText$
	call MemFill

	; print the error message
	pop eax
	push dword [exceptionAddress]
	push dword [exceptionSelector]
	push kPrintText$
	push eax
	call StringBuild
	push kPrintText$
	call Print32

	; dump the registers
	inc byte [cursorY]
	push .text1$
	call Print32
	popa
	call PrintRegs32

	; clear the print string
	push dword 0
	push dword 256
	push kPrintText$
	call MemFill

	; print eflags
	inc byte [cursorY]
	push dword [exceptionFlags]
	push dword [exceptionFlags]
	push kPrintText$
	push .format$
	call StringBuild
	push kPrintText$
	call Print32

	; print bytes at cs:eip
	inc byte [cursorY]
	push .text2$
	call Print32
	push 1
	push dword [exceptionAddress]
	call PrintRAM32

	; print stack dump
	inc byte [cursorY]
	push .text3$
	call Print32
	call StackDump
	
	; print continue message
	inc byte [cursorY]
	push .text4$
	call Print32

	; turn interrupts back on so we gan get keypresses again
	sti

	; wait for a ket to be pressed
	call KeyWait
	pop eax
	
	; disable those interrupts again before we hurt somebody
	cli

	; clear screen to black
	mov byte [backColor], 0x00
	mov byte [textColor], 0x07
	call ScreenClear32

	push dword [.returnAddress]
ret

section .data
.format$										db ' Flags: ^b (0x^h)', 0x00
.text1$											db ' Register contents:   (See stack dump for actual value of ESP at trap)',0x00
.text2$											db ' Bytes at CS:EIP:',0x00
.text3$											db ' Stack dump:',0x00
.text4$											db ' Press any key to attempt resume.',0x00

section .bss
.returnAddress									resd 1





section .text
IDTInit:
	; Initializes the kernel IDT
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a


	push ebp
	mov ebp, esp

	; allocate 64 KiB for the IDT
	push dword 65536
	push dword 1
	call MemAllocate
	pop eax
	mov dword [kIDTPtr], eax

	; set the proper value into the IDT struct
	mov dword [tIDT.base], eax

	; set all the handler slots to the "unsupported routine" handler for sanity
	mov ecx, 0x00000100
	setupOneVector:
		; preserve our counter
		push ecx

		; map the interrupt
		push 0x8E
		push InterruptUnimplemented
		push 0x08
		push ecx
		call InterruptHandlerSet

		; restore our counter
		pop ecx
	loop setupOneVector

	; activate that IDT!
	lidt [tIDT]

	mov esp, ebp
	pop ebp
ret

tIDT:
.limit											dw 2047
.base											dd 0x00000000





section .text
InterruptHandlerGetAddress:
	; Returns the selector, handler address, and flags for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	ISR address

	push ebp
	mov ebp, esp


	; calculate the address of the element in question
	mov ebx, dword [ebp + 8]
	mov eax, 8
	mul ebx
	mov esi, dword [kIDTPtr]
	add esi, eax


	; get what we came for and leave!
	mov eax, 0x00000000
	add esi, 6
	mov ax, word [esi]
	shl eax, 16
	sub esi, 6
	mov ax, word [esi]
	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret





section .text
InterruptHandlerGetFlags:
	; Returns the selector, handler address, and flags for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	Flags

	push ebp
	mov ebp, esp


	; calculate the address of the element in question
	mov ebx, dword [ebp + 8]
	mov eax, 8
	mul ebx
	mov esi, dword [kIDTPtr]
	add esi, eax


	; adjust the address to point to the selector
	add esi, 5


	; get what we came for and leave!
	mov eax, 0x00000000
	mov al, byte [esi]
	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret





section .text
InterruptHandlerGetSelector:
	; Returns the selector, handler address, and flags for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	ISR selector

	push ebp
	mov ebp, esp


	; calculate the address of the element in question
	mov ebx, dword [ebp + 8]
	mov eax, 8
	mul ebx
	mov esi, dword [kIDTPtr]
	add esi, eax


	; adjust the address to point to the selector
	add esi, 2


	; get what we came for and leave!
	mov eax, 0x00000000
	mov ax, word [esi]
	mov dword [ebp + 8], eax


	mov esp, ebp
	pop ebp
ret





section .text
InterruptHandlerSet:
	; Formats the passed data and writes it to the IDT in the slot specified
	;
	;  input:
	;   IDT index
	;   ISR selector
	;   ISR base address
	;   flags
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; calculate the address of the element in question into edi
	mov ebx, dword [ebp + 8]
	mov eax, 8
	mov edx, 0
	mul ebx
	mov edi, dword [kIDTPtr]
	add edi, eax


	; write low word of base address
	mov eax, dword [ebp + 16]
	mov word [edi], ax


	; write selector value
	add edi, 2
	mov eax, dword [ebp + 12]
	mov word [edi], ax


	; write null (reserved byte)
	add edi, 2
	mov al, 0x00
	mov byte [edi], al


	; write those flags!
	inc edi
	mov eax, dword [ebp + 20]
	mov byte [edi], al


	; write high word of base address
	inc edi
	mov eax, dword [ebp + 16]
	shr eax, 16
	mov word [edi], ax


	mov esp, ebp
	pop ebp
ret





section .text
InterruptUnimplemented:
	; A generic handler to run when an unimplemented interrupt is called
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	pusha
jmp $ ; for debugging, makes sure the system hangs for now
	push kUnsupportedInt$
	call PrintRegs32
	call PICIntComplete
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISRInitAll:
	; Sets all the kernel interrupt handler addresses into the IDT
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	push 0x8e
	push ISR00
	push 0x08
	push 0x00
	call InterruptHandlerSet

	push 0x8e
	push ISR01
	push 0x08
	push 0x01
	call InterruptHandlerSet

	push 0x8e
	push ISR02
	push 0x08
	push 0x02
	call InterruptHandlerSet

	push 0x8e
	push ISR03
	push 0x08
	push 0x03
	call InterruptHandlerSet

	push 0x8e
	push ISR04
	push 0x08
	push 0x04
	call InterruptHandlerSet

	push 0x8e
	push ISR05
	push 0x08
	push 0x05
	call InterruptHandlerSet

	push 0x8e
	push ISR06
	push 0x08
	push 0x06
	call InterruptHandlerSet

	push 0x8e
	push ISR07
	push 0x08
	push 0x07
	call InterruptHandlerSet

	push 0x8e
	push ISR08
	push 0x08
	push 0x08
	call InterruptHandlerSet

	push 0x8e
	push ISR09
	push 0x08
	push 0x09
	call InterruptHandlerSet

	push 0x8e
	push ISR0A
	push 0x08
	push 0x0A
	call InterruptHandlerSet

	push 0x8e
	push ISR0B
	push 0x08
	push 0x0B
	call InterruptHandlerSet

	push 0x8e
	push ISR0C
	push 0x08
	push 0x0C
	call InterruptHandlerSet

	push 0x8e
	push ISR0D
	push 0x08
	push 0x0D
	call InterruptHandlerSet

	push 0x8e
	push ISR0E
	push 0x08
	push 0x0E
	call InterruptHandlerSet

	push 0x8e
	push ISR0F
	push 0x08
	push 0x0F
	call InterruptHandlerSet

	push 0x8e
	push ISR10
	push 0x08
	push 0x10
	call InterruptHandlerSet

	push 0x8e
	push ISR11
	push 0x08
	push 0x11
	call InterruptHandlerSet

	push 0x8e
	push ISR12
	push 0x08
	push 0x12
	call InterruptHandlerSet

	push 0x8e
	push ISR13
	push 0x08
	push 0x13
	call InterruptHandlerSet

	push 0x8e
	push ISR14
	push 0x08
	push 0x14
	call InterruptHandlerSet

	push 0x8e
	push ISR15
	push 0x08
	push 0x15
	call InterruptHandlerSet

	push 0x8e
	push ISR16
	push 0x08
	push 0x16
	call InterruptHandlerSet

	push 0x8e
	push ISR17
	push 0x08
	push 0x17
	call InterruptHandlerSet

	push 0x8e
	push ISR18
	push 0x08
	push 0x18
	call InterruptHandlerSet

	push 0x8e
	push ISR19
	push 0x08
	push 0x19
	call InterruptHandlerSet

	push 0x8e
	push ISR1A
	push 0x08
	push 0x1A
	call InterruptHandlerSet

	push 0x8e
	push ISR1B
	push 0x08
	push 0x1B
	call InterruptHandlerSet

	push 0x8e
	push ISR1C
	push 0x08
	push 0x1C
	call InterruptHandlerSet

	push 0x8e
	push ISR1D
	push 0x08
	push 0x1D
	call InterruptHandlerSet

	push 0x8e
	push ISR1E
	push 0x08
	push 0x1E
	call InterruptHandlerSet

	push 0x8e
	push ISR1F
	push 0x08
	push 0x1F
	call InterruptHandlerSet

	push 0x8e
	push ISR20
	push 0x08
	push 0x20
	call InterruptHandlerSet

	push 0x8e
	push ISR21
	push 0x08
	push 0x21
	call InterruptHandlerSet

	push 0x8e
	push ISR22
	push 0x08
	push 0x22
	call InterruptHandlerSet

	push 0x8e
	push ISR23
	push 0x08
	push 0x23
	call InterruptHandlerSet

	push 0x8e
	push ISR24
	push 0x08
	push 0x24
	call InterruptHandlerSet

	push 0x8e
	push ISR25
	push 0x08
	push 0x25
	call InterruptHandlerSet

	push 0x8e
	push ISR26
	push 0x08
	push 0x26
	call InterruptHandlerSet

	push 0x8e
	push ISR27
	push 0x08
	push 0x27
	call InterruptHandlerSet

	push 0x8e
	push ISR28
	push 0x08
	push 0x28
	call InterruptHandlerSet

	push 0x8e
	push ISR29
	push 0x08
	push 0x29
	call InterruptHandlerSet

	push 0x8e
	push ISR2A
	push 0x08
	push 0x2A
	call InterruptHandlerSet

	push 0x8e
	push ISR2B
	push 0x08
	push 0x2B
	call InterruptHandlerSet

	push 0x8e
	push ISR2C
	push 0x08
	push 0x2C
	call InterruptHandlerSet

	push 0x8e
	push ISR2D
	push 0x08
	push 0x2D
	call InterruptHandlerSet

	push 0x8e
	push ISR2E
	push 0x08
	push 0x2E
	call InterruptHandlerSet

	push 0x8e
	push ISR2F
	push 0x08
	push 0x2F
	call InterruptHandlerSet

	mov esp, ebp
	pop ebp
ret





section .text
ISR00:
	; Divide by Zero Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]

iretd

section .data
.error$											db ' Divide by zero fault at ^p4^h:^p8^h ', 0x00





section .text
ISR01:
	; Debug Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Debug trap at ^p4^h:^p8^h', 0x00





section .text
ISR02:
	; Nonmaskable Interrupt Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Non-maskable interrupt at ^p4^h:^p8^h', 0x00





section .text
ISR03:
	; Breakpoint Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]

iretd

section .data
.error$											db ' Breakpoint trap at ^p4^h:^p8^h ', 0x00





section .text
ISR04:
	; Overflow Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Overflow trap at ^p4^h:^p8^h', 0x00





section .text
ISR05:
	; Bound Range Exceeded Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Bound range fault at ^p4^h:^p8^h', 0x00





section .text
ISR06:
	; Invalid Opcode Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]

iretd

section .data
.error$											db ' Invalid Opcode fault at ^p4^h:^p8^h ', 0x00





section .text
ISR07:
	; Device Not Available Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Device unavailable fault at ^p4^h:^p8^h', 0x00





section .text
ISR08:
	; Double Fault Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Double fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR09:
	; Former Coprocessor Segment Overrun Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Coprocessor segment fault at ^p4^h:^p8^h', 0x00





section .text
ISR0A:
	; Invalid TSS Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Invalid TSS fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR0B:
	; Segment Not Present Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Segment not present fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR0C:
	; Stack Segment Fault Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Stack segment fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR0D:
	; General Protection Fault

	; get the error code off the stack
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]

iretd

section .data
.error$											db ' General protection fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR0E:
	; Page Fault Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Page fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR0F:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x0F at ^p4^h:^p8^h', 0x00





section .text
ISR10:
	; x87 Floating Point Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Floating point (x87) fault at ^p4^h:^p8^h', 0x00





section .text
ISR11:
	; Alignment Check Exception

	; get the error code 
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Alignment fault at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR12:
	; Machine Check Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Machine check fault at ^p4^h:^p8^h', 0x00





section .text
ISR13:
	; SIMD Floating Point Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Floating point (SIMD) fault at ^p4^h:^p8^h', 0x00





section .text
ISR14:
	; Virtualization Exception

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Virtualization fault at ^p4^h:^p8^h', 0x00





section .text
ISR15:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x15 at ^p4^h:^p8^h', 0x00





section .text
ISR16:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x16 at ^p4^h:^p8^h', 0x00





section .text
ISR17:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x17 at ^p4^h:^p8^h', 0x00





section .text
ISR18:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x18 at ^p4^h:^p8^h', 0x00





section .text
ISR19:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x19 at ^p4^h:^p8^h', 0x00





section .text
ISR1A:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x1A at ^p4^h:^p8^h', 0x00





section .text
ISR1B:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x1B at ^p4^h:^p8^h', 0x00





section .text
ISR1C:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x1C at ^p4^h:^p8^h', 0x00






section .text
ISR1D:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x1D at ^p4^h:^p8^h', 0x00





section .text
ISR1E:
	; Security Exception

	; get error code
	pop edx

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Security exception at ^p4^h:^p8^h (Error code in EDX)', 0x00





section .text
ISR1F:
	; Reserved

	; get the location of the bad instruction off the stack
	pop dword [exceptionAddress]
	pop dword [exceptionSelector]
	pop dword [exceptionFlags]

	; adjustment to point to the actual break address
	dec dword [exceptionAddress]

	; BSOD!!!
	pusha
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

	; increment the address to which we return
	inc dword [exceptionAddress]

	; push stuff on the stack for return
	push dword [exceptionFlags]
	push dword [exceptionSelector]
	push dword [exceptionAddress]
iretd

section .data
.error$											db ' Exception 0x1F at ^p4^h:^p8^h', 0x00





section .text
ISR20:
	; Programmable Interrupt Timer (PIT)
	push ebp
	mov ebp, esp

	pusha
	pushf

	inc dword [tSystem.ticksSinceBoot]


	; jump to the next task
	;push dword 0
	;call TaskDetermineNext
	;call TaskSwitch

	call PICIntComplete

	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR21:
	; PS/2 Port 1
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000021
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR22:
	; Cascade - used internally by the PICs, should never fire
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000022
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR23:
	; Serial port 2
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000023
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR24:
	; Serial port 1
	push ebp
	mov ebp, esp

	pusha
	pushf
	;push 1
	;call SerialGetIIR
	;pop edx
	;pop ecx
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR25:
	; Parallel port 2
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000025
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR26:
	; Floppy disk
	push ebp
	mov ebp, esp

	; the kernel does nothing directly with the floppy drives, so we can simply exit here
	pusha
	pushf
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR27:
	; Parallel port 1 - prone to misfire
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000027
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR28:
	; CMOS real time clock
	push ebp
	mov ebp, esp

	pusha
	pushf
	; grab the time values from the RTC

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



	; see which hour mode is in use
	mov al, byte [tSystem.RTCStatusRegisterB]
	test al, 00000010b
	jnz .Using24
		; if we get here, 12 hour mode is being used so we adjust the values accordingly

		; first, we see if bit 7 is set, which is used to signify PM
		mov al, byte [tSystem.hours]
		test al, 10000000b
		jz .NotPM
			; if we get here, the PM bit was set
			and al, 01111111b

			; now adjust to 24 hour since that's all the kernel uses internally
			; see if we're using binary format
			test byte [tSystem.RTCStatusRegisterB], 00000100b
			jnz .BinaryHourAdjust

				; if we get here, BCD mode is being used, so we do the comparison in BCD
				cmp al, 0x12
				je .ModificationsComplete

				; if we get here, we need to adjust to 24 hour time using BCD
				add al, 0x12
				jmp .ModificationsComplete

			.BinaryHourAdjust:
			; if we get here, binary mode is being used, so we do the comparison in binary
			cmp al, 12
			je .ModificationsComplete

			; if we get here, we need to adjust to 24 hour time using binary
			add al, 12
			jmp .ModificationsComplete

		.NotPM:
		; see if the hour is 12 or 0x12 and zero it
		cmp al, 12
		je .AdjustAM

		cmp al, 0x12
		je .AdjustAM

		jmp .ModificationsComplete

		.AdjustAM:
		mov al, 0

		.ModificationsComplete:

		; and finally, write the modified value back to the tSystem struct
		mov byte [tSystem.hours], al
	.Using24:
	; if we get here, 24 hour mode is being used, so no adjustment is needed



	; see if we're using binary format and set the appropriate handler address
	test byte [tSystem.RTCStatusRegisterB], 00000100b
	jnz .UsingBinary
		; if we get here, BCD mode is being used so we adjust the values accordingly
		call RTCAdjustBCD
	.UsingBinary:
	; if we get here, Binary mode is being used, so no adjustment is needed



	; Read Status Register C to tell the RTC we're good for another interrupt.
	; We don't need to actually parse the result of this to see which of the three possible RTC interrupt
	; types it was that just fired since we know we only have one of them enabled anyway.
	mov al, 0x0C
	out 0x70, al
	in al, 0x71

	; signal the end of the interrupt to the PIC
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR29:
	; Free for peripherals / legacy SCSI / NIC
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000029
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2A:
	; Free for peripherals / SCSI / NIC
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002A
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2B:
	; Free for peripherals / SCSI / NIC
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002B
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2C:
	; PS/2 Port 2
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002C
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2D:
	; FPU / Coprocessor / Inter-processor
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002D
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2E:
	; Primary ATA Hard Disk
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002E
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR2F:
	; Secondary ATA Hard Disk
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x0000002F
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd
