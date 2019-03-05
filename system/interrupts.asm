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
; InterruptHandlerSet			Formats the passed data and writes it to the IDT in the slot specified
; InterruptUnimplemented		A generic handler to run when an unimplemented interrupt is called
; ISRInitAll					Sets the interrupt handler addresses into the IDT



bits 32



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
.returnAddress									dd 0x00000000
.format$										db ' Flags: ^b (0x^h)', 0x00
.text1$											db ' Register contents:   (See stack dump for actual value of ESP at trap)',0x00
.text2$											db ' Bytes at CS:EIP:',0x00
.text3$											db ' Stack dump:',0x00
.text4$											db ' Press any key to attempt resume.',0x00



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
		push 0x8e
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

	; save return address
	pop esi

	pop ebx										; get destination IDT index
	mov eax, 8									; calc the destination offset into the IDT
	mul ebx
	mov edi, [kIDTPtr]							; get IDT's base address
	add edi, eax								; calc the actual write address

	pop ebx										; get ISR selector

	pop ecx										; get ISR base address

	mov eax, 0x0000FFFF
	and eax, ecx								; get low word of base address in eax
	mov word [edi], ax							; write low word
	add edi, 2									; adjust the destination pointer

	mov word [edi], bx							; write selector
	add edi, 2									; adjust the destination pointer again

	mov al, 0x00
	mov byte [edi], al							; write null (reserved byte)
	inc edi										; adjust the destination pointer again

	pop edx										; get the flags
	mov byte [edi], dl							; and write those flags!
	inc edi										; guess what we're doing here :D

	shr ecx, 16									; shift base address right 16 bits to
												; get high word in position
	mov eax, 0x0000FFFF
	and eax, ecx								; get high word of base address in eax
	mov word [edi], ax							; write high word

	push esi									; restore ret address
ret



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
.error$											db ' Divide by zero fault at ^p4^h:^p8^h ', 0x00



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
.error$											db ' Debug trap at ^p4^h:^p8^h', 0x00



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
.error$											db ' Non-maskable interrupt at ^p4^h:^p8^h', 0x00



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
.error$											db ' Breakpoint trap at ^p4^h:^p8^h ', 0x00



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
.error$											db ' Overflow trap at ^p4^h:^p8^h', 0x00



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
.error$											db ' Bound range fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Invalid Opcode fault at ^p4^h:^p8^h ', 0x00



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
.error$											db ' Device unavailable fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Double fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Coprocessor segment fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Invalid TSS fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Segment not present fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Stack segment fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' General protection fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Page fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Exception 0x0F at ^p4^h:^p8^h', 0x00



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
.error$											db ' Floating point (x87) fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Alignment fault at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Machine check fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Floating point (SIMD) fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Virtualization fault at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x15 at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x16 at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x17 at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x18 at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x19 at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x1A at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x1B at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x1C at ^p4^h:^p8^h', 0x00



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
.error$											db ' Exception 0x1D at ^p4^h:^p8^h', 0x00



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
.error$											db ' Security exception at ^p4^h:^p8^h (Error code in EDX)', 0x00



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
.error$											db ' Exception 0x1F at ^p4^h:^p8^h', 0x00



ISR20:
	; Programmable Interrupt Timer (PIT)
	push ebp
	mov ebp, esp

	pusha
	pushf

	inc dword [tSystem.ticksSinceBoot]
	inc byte [tSystem.ticks]
	cmp byte [tSystem.ticks], 0
	jne .done
	inc dword [tSystem.secondsSinceBoot]
	inc byte [tSystem.seconds]
	cmp byte [tSystem.seconds], 60
	jne .done
	mov byte [tSystem.seconds], 0
	inc byte [tSystem.minutes]
	cmp byte [tSystem.minutes], 60
	jne .done
	mov byte [tSystem.minutes], 0
	inc byte [tSystem.hours]
	cmp byte [tSystem.hours], 24
	jne .done
	mov byte [tSystem.hours], 0
	inc byte [tSystem.day]
	cmp byte [tSystem.day], 30				; this will need modified to account for the different number of days in the months
	jne .done
	mov byte [tSystem.day], 0
	inc byte [tSystem.month]
	cmp byte [tSystem.month], 13
	jne .done
	mov byte [tSystem.month], 1
	inc byte [tSystem.year]
	cmp byte [tSystem.year], 100
	jne .done
	mov byte [tSystem.year], 0
	inc byte [tSystem.century]

	.done:
	call PICIntComplete

	popf
	popa

	mov esp, ebp
	pop ebp
iretd



ISR21:
	; Keyboard
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov eax, 0x00000000
	in al, 0x60

	; skip if this isn't a key down event
	cmp al, 0x80
	ja .done

	; load the buffer position
	mov esi, kKeyBuffer
	mov edx, 0x00000000
	mov dl, [kKeyBufferWrite]
	add esi, edx

	; get the letter or symbol associated with this key code
	mov ebx, kKeyTable
	add ebx, eax
	mov cl, [ebx]

	; add the letter or symbol to the key buffer
	mov byte [esi], cl

	; if the buffer isn't full, adjust the buffer pointer
	mov dh, [kKeyBufferRead]
	inc dl
	cmp dl, dh
	jne .incrementCounter

	.done:
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd
.incrementCounter:
 mov [kKeyBufferWrite], dl
jmp .done



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



ISR28:
	; CMOS real time clock
	push ebp
	mov ebp, esp

	pusha
	pushf
	mov edx, 0x00000028
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd



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



ISR2C:
	; PS/2 Mouse
	push ebp
	mov ebp, esp

	pusha
	pushf

	mov eax, 0x00000000
	in al, 0x60

	; add this byte to the mouse packet
	mov ebx, tSystem.mousePacketByte1
	mov ecx, 0x00000000
	mov cl, [tSystem.mousePacketByteCount]
	mov dl, [tSystem.mousePacketByteSize]
	add ebx, ecx
	mov byte [ebx], al

	; see if we have a full set of bytes, skip to the end if not
	inc cl
	cmp cl, dl
	jne .done

	; if we get here, we have a whole packet
	mov byte [tSystem.mousePacketByteCount], 0xFF

	mov edx, 0x00000000
	mov byte dl, [tSystem.mousePacketByte1]

	; save edx, mask off the three main mouse buttons, restore edx
	push edx
	and dl, 00000111b
	mov byte [tSystem.mouseButtons], dl
	pop edx

	; process the X axis
	mov eax, 0x00000000
	mov ebx, 0x00000000
	mov byte al, [tSystem.mousePacketByte2]
	mov word bx, [tSystem.mouseX]
	push edx
	and dl, 00010000b
	cmp dl, 00010000b
	pop edx
	jne .mouseXPositive
	; movement was negative
	neg al
	sub ebx, eax
	; see if the mouse position would be beyond the left side of the screen, correct if necessary
	cmp ebx, 0x0000FFFF
	ja .mouseXNegativeAdjust
	jmp .mouseXDone
	.mouseXPositive:
	; movement was positive
	add ebx, eax
	; see if the mouse position would be beyond the right side of the screen, correct if necessary
	mov ax, [tSystem.mouseXLimit]
	cmp ebx, eax
	jae .mouseXPositiveAdjust
	.mouseXDone:
	mov word [tSystem.mouseX], bx

	; process the Y axis
	mov eax, 0x00000000
	mov ebx, 0x00000000
	mov byte al, [tSystem.mousePacketByte3]
	mov word bx, [tSystem.mouseY]
	and dl, 00100000b
	cmp dl, 00100000b
	jne .mouseYPositive
	; movement was negative (but we add to counteract the mouse's cartesian coordinate system)
	neg al
	add ebx, eax
	; see if the mouse position would be beyond the bottom of the screen, correct if necessary
	mov ax, [tSystem.mouseYLimit]
	cmp ebx, eax
	jae .mouseYPositiveAdjust
	jmp .mouseYDone
	.mouseYPositive:
	; movement was positive (but we subtract to counteract the mouse's cartesian coordinate system)
	sub ebx, eax
	; see if the mouse position would be beyond the top of the screen, correct if necessary
	cmp ebx, 0x0000FFFF
	ja .mouseYNegativeAdjust
	.mouseYDone:
	mov word [tSystem.mouseY], bx

	; see if we're using a FancyMouse(TM) and act accordingly
	mov byte al, [tSystem.mouseID]
	cmp al, 0x03
	jne .done
	; if we get here, we need have a wheel and need to process the Z axis
	mov eax, 0x00000000
	mov byte al, [tSystem.mousePacketByte4]
	mov word bx, [tSystem.mouseZ]
	mov cl, 0xF0
	and cl, al
	cmp cl, 0xF0
	jne .mouseZPositive
	; movement was negative
	neg al
	and al, 0x0F
	sub bx, ax
	jmp .mouseZDone
	.mouseZPositive:
	; movement was positive
	add bx, ax
	.mouseZDone:
	mov word [tSystem.mouseZ], bx

	.done:
	inc byte [tSystem.mousePacketByteCount]
	call PICIntComplete
	popf
	popa

	mov esp, ebp
	pop ebp
iretd

.mouseXNegativeAdjust:
	mov bx, 0x00000000
jmp .mouseXDone

.mouseXPositiveAdjust:
	mov word bx, [tSystem.mouseXLimit]
	dec bx
jmp .mouseXDone

.mouseYNegativeAdjust:
	mov bx, 0x00000000
jmp .mouseYDone

.mouseYPositiveAdjust:
	mov word bx, [tSystem.mouseYLimit]
	dec bx
jmp .mouseYDone



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



kUnsupportedInt$								db 'An unsupported interrupt has been called', 0x00
exceptionSelector								dd 0x00000000
exceptionAddress								dd 0x00000000
exceptionFlags									dd 0x00000000
kIDTPtr											dd 0x00000000
