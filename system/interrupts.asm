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
; TaskSwitch					Performs a context switch to the next task





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
	;	address of error description string		[ebp + 8]
	;	task number of erroneous instruction	[ebp + 12]
	;	EDI register at time of trap			[ebp + 16]
	;	ESI register at time of trap			[ebp + 20]
	;	EBP register at time of trap			[ebp + 24]
	;	ESP register at time of trap			[ebp + 28]
	;	EBX register at time of trap			[ebp + 32]
	;	EDX register at time of trap			[ebp + 36]
	;	ECX register at time of trap			[ebp + 40]
	;	EAX register at time of trap			[ebp + 44]
	;	address of offending instruction		[ebp + 48]
	;	selector of offending instruction		[ebp + 52]
	;	eflags register at time of trap			[ebp + 56]
	;
	;  output:
	;	n/a


	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 8
	%define textColor							dword [ebp - 4]
	%define backColor							dword [ebp - 8]


	; init color values
	mov textColor, 7
	mov backColor, 1


	; clear the screen to the background color
	push backColor
	call ScreenClear32


	; adjust the ESP we were given to its real location
	mov eax, dword [ebp + 28]
	add eax, 12
	mov dword [ebp + 28], eax


	; prep the print string
	push 80
	push .scratch$
	push dword [ebp + 8]
	call MemCopy


	; build the selector and address into the error string, then print
	push dword 4
	push dword [ebp + 52]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 48]
	push .scratch$
	call StringTokenHexadecimal

	push dword 2
	push dword [ebp + 12]
	push .scratch$
	call StringTokenHexadecimal

	push dword backColor
	push dword textColor
	push dword 1
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; build and print the task number, and name if available
	push 80
	push .scratch$
	push .taskFormat$
	call MemCopy

	push dword 2
	push dword [ebp + 12]
	push .scratch$
	call StringTokenHexadecimal

	mov esi, dword [tSystem.currentTaskSlotAddress]
	add esi, 32
	push dword 0
	push esi
	push .scratch$
	call StringTokenString

	push dword backColor
	push dword textColor
	push dword 3
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; build and print the register dumps
	push dword backColor
	push dword textColor
	push dword 5
	push dword 1
	push .registerText$
	call Print32
	pop eax
	pop eax

	; prep the print string
	push 80
	push .scratch$
	push .registerFormat1$
	call MemCopy

	push dword 8
	push dword [ebp + 44]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 32]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 40]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 36]
	push .scratch$
	call StringTokenHexadecimal

	push dword backColor
	push dword textColor
	push dword 6
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax

	; prep the print string
	push 80
	push .scratch$
	push .registerFormat2$
	call MemCopy

	push dword 8
	push dword [ebp + 24]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 28]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 20]
	push .scratch$
	call StringTokenHexadecimal

	push dword 8
	push dword [ebp + 16]
	push .scratch$
	call StringTokenHexadecimal

	push dword backColor
	push dword textColor
	push dword 7
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; prep the print string
	push 80
	push .scratch$
	push .eflagsFormat$
	call MemCopy


	; print eflags
	push dword 8
	push dword [ebp + 56]
	push .scratch$
	call StringTokenHexadecimal

	push dword 32
	push dword [ebp + 56]
	push .scratch$
	call StringTokenBinary


	push dword backColor
	push dword textColor
	push dword 9
	push dword 1
	push .scratch$
	call Print32
	pop eax
	pop eax


	; build and print bytes at cs:eip
	push dword backColor
	push dword textColor
	push dword 11
	push dword 1
	push .EIPText$
	call Print32
	pop eax
	pop eax


	push dword backColor
	push dword textColor
	push dword 12
	push dword 1
	push dword 1
	push dword [ebp + 48]
	call PrintRAM32


	; print stack dump
	push dword backColor
	push dword textColor
	push dword 14
	push dword 1
	push .stackDumpText$
	call Print32
	pop eax
	pop eax

	push dword backColor
	push dword textColor
	push dword 15
	push dword 1
	mov eax, 0
	mov al, byte [kMaxLines]
	sub eax, 16
	push eax
	push dword [ebp + 28]
	call PrintRAM32


	; print exit text
	push dword backColor
	push dword textColor
	mov eax, 0
	mov al, byte [kMaxLines]
	push eax
	push dword 16
	push .exitText$
	call Print32
	pop eax
	pop eax


	; pause tasking and turn interrupts back on so we can get keypresses again
	; You may ask, "Isn't that dangerous?"
	; To which I ask, "Does Bill Withers know?" Spoiler alert: he does.
	; We should probably come up with a better method in the future.
	mov byte [tSystem.taskingEnable], 0
	sti


	; wait for a ket to be pressed
	call KeyWait
	pop eax

	
	; disable those interrupts again before we hurt somebody, and re-enable tasking
	cli
	mov byte [tSystem.taskingEnable], 1


	; kill the rogue task
	push dword [ebp + 12]
	call TaskKill


	; clear screen to black
	push 0x00000000
	call ScreenClear32


	mov esp, ebp
	pop ebp
ret 40

section .data
.eflagsFormat$									db 'Flags: 0x^ (^)', 0x00
.taskFormat$									db 'Caused by task 0x^ ^', 0x00
.registerText$									db 'Register contents:',0x00
.registerFormat1$								db 'EAX: 0x^    EBX: 0x^    ECX: 0x^    EDX: 0x^', 0x00
.registerFormat2$								db 'EBP: 0x^    ESP: 0x^    ESI: 0x^    EDI: 0x^', 0x00
.EIPText$										db 'Bytes at EIP:',0x00
.stackDumpText$									db 'Bytes on stack:',0x00
.exitText$										db 0x27, 'Tis a sad thing that your process has ended here!', 0x00

section .bss
.scratch$										resb 80





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
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Divide by zero fault at ^:^', 0x00





section .text
ISR01:
	; Debug Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Debug trap at ^:^', 0x00





section .text
ISR02:
	; Nonmaskable Interrupt Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Non-maskable interrupt at ^:^', 0x00





section .text
ISR03:
	; Breakpoint Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Breakpoint trap at ^:^', 0x00





section .text
ISR04:
	; Overflow Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Overflow trap at ^:^', 0x00





section .text
ISR05:
	; Bound Range Exceeded Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Bound range fault at ^:^', 0x00





section .text
ISR06:
	; Invalid Opcode Exception

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete

jmp TaskSwitch

section .data
.error$											db 'Invalid Opcode fault at ^:^', 0x00





section .text
ISR07:
	; Device Not Available Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Device unavailable fault at ^:^', 0x00





section .text
ISR08:
	; Double Fault Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Double fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR09:
	; Former Coprocessor Segment Overrun Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Coprocessor segment fault at ^:^', 0x00





section .text
ISR0A:
	; Invalid TSS Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db ' Invalid TSS fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR0B:
	; Segment Not Present Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Segment not present fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR0C:
	; Stack Segment Fault Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Stack segment fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR0D:
	; General Protection Fault

	; get the error code off the stack
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'General protection fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR0E:
	; Page Fault Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Page fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR0F:
	; Reserved

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x0F at ^:^', 0x00





section .text
ISR10:
	; x87 Floating Point Exception

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Floating point (x87) fault at ^:^', 0x00





section .text
ISR11:
	; Alignment Check Exception

	; get the error code 
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Alignment fault at ^:^ (Error code in EDX)', 0x00





section .text
ISR12:
	; Machine Check Exception

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Machine check fault at ^:^', 0x00





section .text
ISR13:
	; SIMD Floating Point Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Floating point (SIMD) fault at ^:^', 0x00





section .text
ISR14:
	; Virtualization Exception
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Virtualization fault at ^:^', 0x00





section .text
ISR15:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x15 at ^:^', 0x00





section .text
ISR16:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x16 at ^:^', 0x00





section .text
ISR17:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x17 at ^:^', 0x00





section .text
ISR18:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x18 at ^:^', 0x00





section .text
ISR19:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x19 at ^:^', 0x00





section .text
ISR1A:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x1A at ^:^', 0x00





section .text
ISR1B:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x1B at ^:^', 0x00





section .text
ISR1C:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x1C at ^:^', 0x00






section .text
ISR1D:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x1D at ^:^', 0x00





section .text
ISR1E:
	; Security Exception

	; get error code
	pop edx

	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Security exception at ^:^ (Error code in EDX)', 0x00





section .text
ISR1F:
	; Reserved
	pusha
	push dword [tSystem.currentTask]
	push .error$
	call CriticalError

	; acknowledge the PIC
	call PICIntComplete
jmp TaskSwitch

section .data
.error$											db 'Exception 0x1F at ^:^', 0x00





section .text
ISR20:
	; Programmable Interrupt Timer (PIT)

	inc dword [tSystem.ticksSinceBoot]

	pusha
	call PICIntComplete
	popa

jmp TaskSwitch





section .text
ISR21:
	; PS/2 Port 1
	push ebp
	mov ebp, esp

	pusha
	mov edx, 0x00000021
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
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
	mov edx, 0x00000022
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	mov edx, 0x00000023
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	;push 1
	;call SerialGetIIR
	;pop edx
	;pop ecx
	call PICIntComplete
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
	mov edx, 0x00000025
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	call PICIntComplete
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
	mov edx, 0x00000027
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
	popa

	mov esp, ebp
	pop ebp
iretd





section .text
ISR28:
	; CMOS real time clock

	pusha

	call RTCInterruptHandler

	; signal the end of the interrupt to the PIC
	call PICIntComplete

	popa

iretd





section .text
ISR29:
	; Free for peripherals / legacy SCSI / NIC
	push ebp
	mov ebp, esp

	pusha
	mov edx, 0x00000029
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	mov edx, 0x0000002A
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	mov edx, 0x0000002B
	jmp $ ; for debugging, makes sure the system hangs upon exception
	call PICIntComplete
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
	mov edx, 0x0000002C
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
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
	mov edx, 0x0000002D
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
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
	mov edx, 0x0000002E
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
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
	mov edx, 0x0000002F
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popa

	mov esp, ebp
	pop ebp
iretd
