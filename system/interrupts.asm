; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; interrupts.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; constants
kIDTPtr											dd 0x00000000





bits 32





section .text
CriticalError:
	; Handles the UI portion of traps and exceptions
	;
	;  input:
	;	Address of error description string		[ebp + 8]
	;	Task number of erroneous instruction	[ebp + 12]
	;	EDI register at time of trap			[ebp + 16]
	;	ESI register at time of trap			[ebp + 20]
	;	EBP register at time of trap			[ebp + 24]
	;	ESP (original) register at time of trap	[ebp + 28]
	;	EBX register at time of trap			[ebp + 32]
	;	EDX register at time of trap			[ebp + 36]
	;	ECX register at time of trap			[ebp + 40]
	;	EAX register at time of trap			[ebp + 44]
	;	Address of offending instruction		[ebp + 48]
	;	Selector of offending instruction		[ebp + 52]
	;	EFlags register at time of trap			[ebp + 56]
	;	ESP (adjusted) register at time of trap	[ebp + 60]
	;	SS register at time of trap				[ebp + 64]
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 12
	%define textColor							dword [ebp - 4]
	%define backColor							dword [ebp - 8]
	%define bytesAtEIP							dword [ebp - 12]


	; before we do anything, let's see if this is a situation we can actually resolve without killing the task
	mov eax, dword [ebp + 48]
	mov ebx, dword [eax]
	mov bytesAtEIP, ebx

	; check for hlt
	cmp bl, 0xF4
	jne .NotHLT
		; Handle the hlt by modifying the eip value passed to the instruction just past the hlt.
		; The net effect here is that the task's turn at the CPU will prematurely end.
		mov eax, dword [ebp + 48]
		inc eax
		mov dword [ebp + 48], eax
		jmp .Done
	.NotHLT:

	cmp bl, 0xFA
	jne .NotCLI
		; Handle the cli by clearing the interrupt flag in the task structure
		mov esi, [tSystem.currentTaskSlotAddress]
		and byte [tTaskInfo.taskFlags], 11111110b

		; point EIP to the next instruction and return
		mov eax, dword [ebp + 48]
		inc eax
		mov dword [ebp + 48], eax
		jmp .Done
	.NotCLI:

	cmp bl, 0xFB
	jne .NotSTI
		; Handle the sti by setting the interrupt flag in the task structure
		mov esi, [tSystem.currentTaskSlotAddress]
		or byte [tTaskInfo.taskFlags], 00000001b


		; point EIP to the next instruction and return
		mov eax, dword [ebp + 48]
		inc eax
		mov dword [ebp + 48], eax
		jmp .Done
	.NotSTI:



	; If we get here, it seems there's simply nothing we can do for this poor task. Off with its head!

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

	push dword backColor
	push dword textColor
	push dword 1
	push dword 1
	push .scratch$
	call Print32


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
	add esi, 64
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


	; build and print the register dumps
	push dword backColor
	push dword textColor
	push dword 5
	push dword 1
	push .registerText$
	call Print32

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
	push dword [ebp + 60]
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


	; build and print bytes at cs:eip
	push dword backColor
	push dword textColor
	push dword 11
	push dword 1
	push .EIPText$
	call Print32


	push dword backColor
	push dword textColor
	push dword 12
	push dword 1
	push dword 1
	push dword [ebp + 48]
	call PrintRAM32


	; print user stack dump
	push dword backColor
	push dword textColor
	push dword 14
	push dword 1
	push .userStackDumpText$
	call Print32

	push dword backColor
	push dword textColor
	push dword 15
	push dword 1
	push 4
	push dword [ebp + 60]
	call PrintRAM32

	; print kernel stack dump
	push dword backColor
	push dword textColor
	push dword 20
	push dword 1
	push .kernelStackDumpText$
	call Print32
	
	; get the location of the stack prior to this error
	mov eax, esp
	add eax, 80

	push dword backColor
	push dword textColor
	push dword 21
	push dword 1
	push 4
	push eax
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


	; pause tasking and turn interrupts back on so we can get keypresses again
	; You may ask, "Isn't that dangerous?"
	; To which I ask, "Does Bill Withers know?" Spoiler alert: he does.
	; We should probably come up with a better method in the future.
	mov byte [tSystem.taskingEnable], 0
	sti


	; wait for a key to be pressed
	push dword 0
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


	.Done:
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
.userStackDumpText$								db 'Bytes on user stack:',0x00
.kernelStackDumpText$							db 'Bytes on kernel stack prior to error:',0x00
.exitText$										db 0x27, 'Tis a sad thing that your process has ended here!', 0x00

section .bss
.scratch$										resb 80





section .text
IDTInit:
	; Initializes the kernel IDT
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate 64 KiB for the IDT
	push dword 65536
	push dword 1
	call MemAllocate
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
	; Returns the handler address for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	EAX - ISR address

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


	mov esp, ebp
	pop ebp
ret 4





section .text
InterruptHandlerGetFlags:
	; Returns the flags for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	EAX - Flags

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


	mov esp, ebp
	pop ebp
ret 4





section .text
InterruptHandlerGetSelector:
	; Returns the selector for the specified interrupt number
	;
	;  input:
	;	IDT index
	;
	;  output:
	;	EAX - ISR selector

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


	mov esp, ebp
	pop ebp
ret 4





section .text
InterruptHandlerSet:
	; Formats the passed data and writes it to the IDT in the slot specified
	;
	;  input:
	;	IDT index
	;	ISR selector
	;	ISR base address
	;	Flags
	;
	;  output:
	;	n/a

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
	;	n/a
	;
	;  output:
	;	n/a

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

section .data
kUnsupportedInt$								db 'An unsupported interrupt has been called', 0x00





section .text
ISRInitAll:
	; Sets all the kernel interrupt handler addresses into the IDT
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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

	; preserve the important stuff
	push ds
	push 0x10
	pop ds
	pusha

	; call the debugger
	push dword [tSystem.currentTask]
	call Debugger

	; acknowledge the PIC
	pusha
	call PICIntComplete
	popa

	; restore DS
	pop ds
iret





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
	; preserve the important stuff
	push ds
	push 0x10
	pop ds
	pusha

	; call the debugger
	push dword [tSystem.currentTask]
	call Debugger

	; acknowledge the PIC
	call PICIntComplete

	; restore DS
	pop ds
iret





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

	; preserving DS isn't necessary, but we do make sure we're on the kernel's data selector
	push 0x10
	pop ds

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
	; Programmable Interval Timer (PIT)

	; we don't need to preserve DS here, since the task switching code will set it straight in a moment anyway
	; however, we DO need to make sure we're on the kernel's data selector
	push 0x10
	pop ds

	inc dword [tSystem.ticksSinceBoot]

	pusha
	call PICIntComplete
	popa

jmp TaskSwitch





section .text
ISR21:
	; PS/2 Port 1

	pusha
	mov edx, 0x00000021
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popa

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
	; Parallel port 1 - Supposedly prone to misfire?
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
	push ds
	push 0x10
	pop ds
	pusha

	call RTCInterruptHandler

	; signal the end of the interrupt to the PIC
	call PICIntComplete

	popa
	pop ds
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

	pusha
	mov edx, 0x0000002C
	jmp $ ; for debugging, makes sure the system hangs upon exception for now
	call PICIntComplete
	popa

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
