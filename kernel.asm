; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; kernel.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; boy, the kernel needs a lot of headers to start! :D
%include "include/kernel.def"

%include "include/CPU.inc"
%include "include/debug.inc"
%include "include/errors.inc"
%include "include/FATFilesystem.inc"
%include "include/globals.inc"
%include "include/hardware.inc"
%include "include/IDEController.inc"
%include "include/interrupts.inc"
%include "include/lists.inc"
%include "include/memory.inc"
%include "include/misc.inc"
%include "include/paging.inc"
%include "include/PCI.inc"
%include "include/PIC.inc"
%include "include/PS2Controller.inc"
%include "include/RTC.inc"
%include "include/screen.inc"
%include "include/storage.inc"
%include "include/strings.inc"
%include "include/tasks.inc"





bits 16





section .text
main:
; Clear the direction flag; nobody knows what weirdness the BIOS did before we got here.
cld

; init the stack segment
mov ax, 0x0000
mov ss, ax
mov sp, 0x0600
mov bp, 0x0000

mov ax, 0x0000
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax


; set hardware text mode
mov ah, 0x00
mov al, 0x03
int 0x10




; check the configbits to see if we should use 50 lines
bt dword [tSystem.configBits], kCBLines50
jnc .stickWith25

	; if we get here, we should shift to 50-line mode
	; first we update the constants
	mov byte [kMaxLines], 50
	mov word [kBytesPerScreen], 8000

	; now we set 8x8 character mode
	mov ax, 0x1112
	int 0x10

; ...or we can jump here to avoid setting that beautugly 50-line mode
.stickWith25:

; hide the hardware cursor
mov ah, 0x01
mov cx, 0x2707
int 0x10

; set text colors
mov byte [gTextColor], 7
mov byte [gBackColor], 0



; init and probe RAM
push progressText01$
call PrintIfConfigBits16
call MemProbe

; see if there was an error
cmp edx, kErrNone
je .MemProbeOK
	; do a fatal error here, 16-bit style
	mov byte [gTextColor], 0
	mov byte [gBackColor], 4
	push fatalE820Unsupported$
	call Print16
.MemProbeOK:



; enable the A20 line - one of the things we require for operation
push progressText02$
call PrintIfConfigBits16
call A20Enable



; get that good ol' APM info
;push progressText03$
;call PrintIfConfigBits16
;call SetSystemAPM



; enable the APM interface
;push progressText04$
;call PrintIfConfigBits16
;call APMEnable



; load that GDT!
push progressText05$
call PrintIfConfigBits16
lgdt [gdt]



; probe the PCI controller while we still can
push progressText06$
call PrintIfConfigBits16
call PCIProbe



; enter protected mode. YAY!
push progressText07$
call PrintIfConfigBits16
mov eax, cr0
or eax, 00000001b
mov cr0, eax

; jump to start the kernel in 32-bit mode
jmp 0x08:ProtectedEntry



bits 32



ProtectedEntry:

; When we were in Real Mode a moment ago, we used some BIOS calls to get things set up.
; Unfortunately, they have a bad habit of enabling interrupts on their own, EVEN when they were not previously enabled.
; That's not so bad for Real Mode, but here in Protected land, that's a Bad Thing waiting to happen.
; So let's disable them again.
cli



; init the registers, including the temporary stack
mov ax, 0x0010
mov ds, ax
mov es, ax
mov ss, ax
mov esp, 0x0009FB00



; turn on CPU debug extensions
push progressText08$
call PrintIfConfigBits32
call DebugCPUFeaturesEnable



; memory list init
push progressText09$
call PrintIfConfigBits32
call MemInit



; now that we have a temporary stack and access to all the memory addresses,
; let's allocate some RAM for the real stack
push progressText0A$
call PrintIfConfigBits32

push kKernelStack
push dword 1
call MemAllocate

; see if there was an error
cmp edx, kErrNone
je .StackAllocOK
	push fatalKernelStackMemAlloc$
	call Fail
.StackAllocOK:

mov ebx, kKernelStack
add eax, ebx
mov esp, eax
; push a null to stop any traces which may attempt to analyze the stack later
push 0x00000000



; set up our interrupt handlers and IDT
push progressText0B$
call PrintIfConfigBits32
call IDTInit

; see if there was an error
cmp edx, kErrNone
je .IDTAllocOK
	push fatalIDTMemAlloc$
	call Fail
.IDTAllocOK:

call ISRInitAll



; setup and remap both PICs
push progressText0C$
call PrintIfConfigBits32
call PICInit
call PICIRQDisableAll
call PICIRQEnableAll
call PITInit



; init the RTC
push progressText0D$
call PrintIfConfigBits32
call RTCInit



; let's get some interrupts firing!
push progressText0E$
call PrintIfConfigBits32
sti



; load system data into the info struct
push progressText0F$
call PrintIfConfigBits32
call SetSystemCPUID



; allocate the system lists
push progressText10$
call PrintIfConfigBits32
call KernelInitLists

; see if there was an error
cmp edx, kErrNone
je .ListInitOK
	push fatalListMemAlloc$
	call Fail
.ListInitOK:



; init PS/2 driver
push progressText11$
call PrintIfConfigBits32
call PS2ControllerInit



; set up default handlers
push progressText12$
call PrintIfConfigBits32
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
call FAT16ServiceHandler

push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
push dword 0
call FAT32ServiceHandler

push IDEServiceHandler
push 1
push 1
call PCIHandlerSet



; init PCI devices
push progressText13$
call PrintIfConfigBits32
call PCIDeviceInitAll



; enumerate partitions
push progressText14$
call PrintIfConfigBits32
call SMPartitionEnumerate


; map partitions
; for now, we just do drive C
push progressText15$
call PrintIfConfigBits32
push 2
push 0
call SMPartitionMap



; init Task Manager
push progressText16$
call PrintIfConfigBits32
call TaskInit



; initialize paging
push progressText17$
call PrintIfConfigBits32
call PagingInit


xchg bx, bx


bt dword [tSystem.configBits], kCBDebugMode
jnc .SkipStartDelay
	; if we get here, we're in Debug Mode
	; wouldn't it be nice if we gave the user a moment to admire all those handy debug messages?
	push 512
	call TimerWait
.SkipStartDelay:



; clear the screen and start!
push 0x00000000
call ScreenClear32



; set up tasks
push dword 0x3202
push Task1
call TaskNew

push Task1.name$
push eax
call TaskNameSet


push dword 0x3202
push Task2
call TaskNew

push Task2.name$
push eax
call TaskNameSet


push dword 0x23202
push Task5
call TaskNew

push Task5.name$
push eax
call TaskNameSet


push dword 0x3202
push DebugMenu
call TaskNew

push name$
push eax
call TaskNameSet


push dword 0x3202
push Task3
call TaskNew

push Task3.name$
push eax
call TaskNameSet





; Got time for a story? Cool. So, turns out there's a funny particularity about the x86 CPU... under normal circumstances, for the sake of
; efficiency, it will only pop off EIP, CS, and EFLAGS upon returning from an ISR. However, for user mode to work right, we need it to also
; pop off new values for SS and ESP. How does we do dis? We have to enter userland temporarily here so that when an interrupt happens, the
; CPU will know to get all five values instead of just three. Is that a kludge? It sure is. But thus is the 86 ISA. And so, without further ado...

; WELCOME TO USERLAND! Please enjoy your stay.



cli

; set the segment registers to the user data selector, with the bottom two bits set to indicate privilege level 3
; 0x20 or 0x03 = 0x23
mov ax, 0x23
mov ds, ax
mov es, ax 
mov fs, ax 
mov gs, ax


; set up just enough to get into user mode
; none of this gets saved once multitasking starts since we can't easily return to kernel mode anyway
push 0x23
push esp
push dword 0x00000202
push 0x1B
push UserModeEntry
mov dword [tss.esp0], esp
iretd


UserModeEntry:
; ye olde obligatory stack fixup
add esp, 4



; and finally, enable multitasking
mov byte [tSystem.taskingEnable], 1


; enter an infinite loop to burn up time until the first PIT interrupt launches the first task
InfiniteLoop:
jmp InfiniteLoop



section .text
Task1:
	; see if a second has passed
	mov al, byte [tSystem.seconds]
	cmp byte [.lastSecond], al
	mov byte [.lastSecond], al
	jne .PrintStuff
	hlt
	jmp Task1

	.PrintStuff:
	; clear our print string
	push 20
	push .scratch1$
	push .dateTimeFormat$
	call MemCopy

	; build the date and time info string
	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.month]
	push eax
	push .scratch1$
	call StringTokenDecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.day]
	push eax
	push .scratch1$
	call StringTokenDecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.year]
	push eax
	push .scratch1$
	call StringTokenDecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.hours]
	push eax
	push .scratch1$
	call StringTokenDecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.minutes]
	push eax
	push .scratch1$
	call StringTokenDecimal

	push dword 2
	mov eax, 0x00000000
	mov al, byte [tSystem.seconds]
	push eax
	push .scratch1$
	call StringTokenDecimal


	; print the string
	push dword 0x00000000
	push dword 0x00000007
	push dword 1
	push dword 64
	push .scratch1$
	call Print32
jmp Task1

section .data
.name$											db 'Date & Time', 0x00
.dateTimeFormat$								db '^/^/^ ^:^:^', 0x00

section .bss
.lastSecond										resb 1
.scratch1$										resb 20



section .text
Task2:
	; init our print string
	push 80
	push .scratch2$
	push .mouseFormat$
	call MemCopy


	; build mouse location string
	push dword 2
	mov eax, 0
	mov ax, word [tSystem.PS2ControllerDeviceID2]
	push eax
	push .scratch2$
	call StringTokenHexadecimal

	push dword 4
	mov eax, 0
	mov ax, word [tSystem.mouseX]
	push eax
	push .scratch2$
	call StringTokenDecimal

	push dword 4
	mov eax, 0
	mov ax, word [tSystem.mouseY]
	push eax
	push .scratch2$
	call StringTokenDecimal

	push dword 5
	mov eax, 0
	mov ax, word [tSystem.mouseZ]
	push eax
	push .scratch2$
	call StringTokenDecimal

	push dword 8
	mov eax, 0
	mov al, byte [tSystem.mouseButtons]
	push eax
	push .scratch2$
	call StringTokenBinary

	; print the string
	push dword 0x00000000
	push dword 0x00000007
	mov eax, 0
	mov al, byte [kMaxLines]
	push eax
	push dword 1
	push .scratch2$
	call Print32
jmp Task2

section .data
.name$											db 'Mouse Tracker', 0x00
.mouseFormat$									db 'Mouse type: ^   X: ^   Y: ^   Z: ^   Buttons: ^   ', 0x00

section .bss
.scratch2$										resb 80



section .text
Task3:
		inc dword [.counter]
		cmp dword [.counter], 0
		jne .NoOverflow
			inc dword [.counter2]
		.NoOverflow:

		; see if a second has passed
		mov al, byte [tSystem.seconds]
		cmp byte [.lastSecond], al
		mov byte [.lastSecond], al
	je Task3

	; if we get here, the second just changed
	; clear our print string
	push 80
	push .scratch3$
	push .performanceFormat$
	call MemCopy


	; build the performance string
	push dword 10
	push dword [.counter]
	push .scratch3$
	call StringTokenDecimal

	push dword 10
	push dword [.counter2]
	push .scratch3$
	call StringTokenDecimal

	push dword 10
	push dword [.counterHighest]
	push .scratch3$
	call StringTokenDecimal

	; calculate CPU load
	mov ecx, 100
	mov eax, dword [.counterHighest]
	cmp eax, dword [.counter]
	jb .SkipLoad

	mov eax, dword [.counterHighest]
	mov edx, 0
	mov ebx, 100
	div ebx
	cmp eax, 0
	je .SkipLoad

	mov ebx, eax
	mov eax, dword [.counter]
	mov edx, 0
	div ebx

	mov ecx, 100
	sub ecx, eax

	.SkipLoad:
	push dword 3
	push ecx
	push .scratch3$
	call StringTokenDecimal

	; print the string
	push dword 0x00000000
	push dword 0x00000007
	mov eax, 0x00000000
	mov al, [kMaxLines]
	dec eax
	push eax
	push dword 1
	push .scratch3$
	call Print32

	; see if we have a new record holder
	mov eax, dword [.counter]
	cmp eax, dword [.counterHighest]
	jb .NotHighest
		mov dword [.counterHighest], eax
	.NotHighest:
	mov dword [.counter], 0
	mov dword [.counter2], 0
jmp Task3

section .data
.name$											db 'Kernel Performance Monitor', 0x00
.performanceFormat$								db 'Performance: ^  Overflow: ^  Highest: ^  Load: ^%', 0x00
.counter										dd 0x00000000
.counter2										dd 0x00000000
.counterHighest									dd 0x00000000

section .bss
.lastSecond										resb 1
.scratch3$										resb 80



section .text
Task4:
	; let's get spawn happy!
	push dword 0x3202
	push Task4
	call TaskNew

	push eax
	call TaskKill

jmp Task4

section .data
.name$											db 'Spawny McSpawnface', 0x00



bits 16
section .text
Task5:
	; v86 testing
	inc ax
	mov bx, cx
	inc cx
	inc dx
	cmp dx, 0xFFFF
	jne .SkipBadInstruction
		mov ax, 88
		mov ds, ax
	.SkipBadInstruction:
jmp Task5

section .data
.name$											db 'V86 Tester', 0x00





section .data
progressText01$									db 'Probing BIOS memory map', 0x00
progressText02$									db 'Beginning A20 enable procedure', 0x00
progressText03$									db 'SetSystemAPM', 0x00
progressText04$									db 'APMEnable', 0x00
progressText05$									db 'LoadGDT', 0x00
progressText06$									db 'Probing PCI controller', 0x00
progressText07$									db 'Entering Protected Mode', 0x00
progressText08$									db 'Enabling CPU debug features', 0x00
progressText09$									db 'Memory list init', 0x00
progressText0A$									db 'Stack setup', 0x00
progressText0B$									db 'IDTInit', 0x00
progressText0C$									db 'Remaping PICs', 0x00
progressText0D$									db 'Initializing RTC', 0x00
progressText0E$									db 'Enabling interrupts', 0x00
progressText0F$									db 'Building System Table', 0x00
progressText10$									db 'Allocating list space', 0x00
progressText11$									db 'Initializing PS/2 driver', 0x00
progressText12$									db 'Setting up default handler addresses', 0x00
progressText13$									db 'Initializing PCI devices', 0x00
progressText14$									db 'Enumerating partitions', 0x00
progressText15$									db 'Mapping partitions', 0x00
progressText16$									db 'Initializing Task Manager', 0x00
progressText17$									db 'Initializing CPU paging features', 0x00
fatalE820Unsupported$							db 'Fatal: BIOS function 0xE820 unsupported on this machine; unable to probe memory', 0x00
fatalIDTMemAlloc$								db 'Fatal: Unable to allocate IDT memory.', 0x00
fatalKernelStackMemAlloc$						db 'Fatal: Unable to allocate kernel stack memory.', 0x00
fatalListMemAlloc$								db 'Fatal: Unable to allocate system list memory.', 0x00
name$											db 'Kernel Debug Menu', 0x00





bits 32





section .text
KernelInitLists:
	; Sets up the lists used by the kernel
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp


	; the drives list will be 256 entries of tDriveInfo structs, plus header
	push dword 256 * tDriveInfo_size + 16
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listDrives], eax

	; set up the list header
	push tDriveInfo_size
	push dword 256
	push eax
	call LMListInit



	; the driveLetters list will be 26 entries (A - Z) of 4 bytes each plus header
	push dword 26 * 4 + 16
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listDriveLetters], eax

	; set all elements to 0xFFFFFFFF
	push dword 0xFF
	push dword 26 * 4 + 16
	push eax
	call MemFill

	; set up the list header
	push dword 4
	push dword 26
	push eax
	call LMListInit



	; the FSHandler list will be 256 entries of 4 bytes each (the size of a single 32-bit address) plus header
	push dword 256 * 4 + 16
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listFSHandlers], eax

	; set up the list header
	push dword 4
	push dword 256
	push eax
	call LMListInit



	; the partitions list will be 256 entries of tPartitionInfo structs, plus header
	; allocate memory for the list
	push dword 256 * tPartitionInfo_size + 16
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPartitions], eax

	; set up the list header
	push dword tPartitionInfo_size
	push dword 256
	push eax
	call LMListInit



	; the PCI handlers list will be 65536 entries of 4 bytes each (the size of a single 32-bit address)
	; allocate memory for the list
	push dword 65536 * 4 + 16
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPCIHandlers], eax

	; set up the list header
	push dword 4
	push dword 65536
	push eax
	call LMListInit


	.Exit:
	mov esp, ebp
	pop ebp
ret





section .data
gdt:
	; Null descriptor (Offset 0x00)
	; this is normally all zeros, but it's also a great place to tuck away the GDT header info
	dw gdt.end - gdt - 1							; size of GDT
	dd gdt											; base of GDT
	dw 0x0000										; filler

	; Kernel space code (Offset 0x08)
	.gdt1:
	dw 0xFFFF										; limit low
	dw 0x0000										; base low
	db 0x00											; base middle
	db 10011010b									; access byte
	db 11001111b									; limit high, flags
	db 0x00											; base high

	; Kernel space data (Offset 0x10)
	.gdt2:
	dw 0xFFFF										; limit low
	dw 0x0000										; base low
	db 0x00											; base middle
	db 10010010b									; access byte
	db 11001111b									; limit high, flags
	db 0x00											; base high

	; User Space code (Offset 0x18)
	.gdt3:
	dw 0xFFFF										; limit low
	dw 0x0000										; base low
	db 0x00											; base middle
	db 11111010b									; access byte
	db 11001111b									; limit high, flags
	db 0x00											; base high

	; User Space data (Offset 0x20)
	.gdt4:
	dw 0xFFFF										; limit low
	dw 0x0000										; base low
	db 0x00											; base middle
	db 11110010b									; access byte
	db 11001111b									; limit high, flags
	db 0x00											; base high

	; Task State Segment (Offset 0x28)
	; Note: the way this is set up assumes the location of the TSS is within the first 64 KiB of RAM and that it is also
	; quite small. Neither of these things should pose a problem in the future, but it's worth noting here for sanity.
	.gdt5:
	dw (tss.end - tss) & 0x0000FFFF					; limit low
	dw tss											; base low
	db 0x00											; base middle
	db 11101001b									; access byte
	db 00000000b									; limit high, flags
	db 0x00											; base high
.end:


tss:
	.back_link										dd 0x00000000
	.esp0											dd 0x00000000
	.ss0											dd 0x00000010
	.esp1											dd 0x00000000
	.ss1											dd 0x00000000
	.esp2											dd 0x00000000
	.ss2											dd 0x00000000
	.cr3											dd 0x00000000
	.eip											dd 0x00000000
	.eflags											dd 0x00000000
	.eax											dd 0x00000000
	.ecx											dd 0x00000000
	.edx											dd 0x00000000
	.ebx											dd 0x00000000
	.esp											dd 0x00000000
	.ebp											dd 0x00000000
	.esi											dd 0x00000000
	.edi											dd 0x00000000
	.es												dd 0x00000000
	.cs												dd 0x00000000
	.ss												dd 0x00000000
	.ds												dd 0x00000000
	.fs												dd 0x00000000
	.gs												dd 0x00000000
	.ldt											dd 0x00000000
	.trap											dw 0x0000
	.iomap_base										dw 0x0000
.end:
