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





[map all kernel.map]
org 0x00000600



bits 16



; constant defines
%define true									1
%define false									0
%define null									0

; for configbits settings - great idea, Antony!
%define kCBDebugMode							0
%define kCBVerbose								1
%define kCBLines50								2
%define kCBVMEnable								3





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

; set kernel cursor location
mov byte [gTextColor], 7
mov byte [gBackColor], 0



; init and probe RAM
push progressText01$
call PrintIfConfigBits16
call MemProbe



; enable the A20 line - one of the things we require for operation
push progressText02$
call PrintIfConfigBits16
call A20Enable



; get that good ol' APM info
push progressText03$
call PrintIfConfigBits16
call SetSystemAPM



; enable the APM interface
push progressText04$
call PrintIfConfigBits16
call APMEnable



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

push dword [kKernelStack]
push dword 1
call MemAllocate

mov ebx, [kKernelStack]
add eax, ebx
mov esp, eax
; push a null to stop any traces which may attempt to analyze the stack later
push 0x00000000



; set up our interrupt handlers and IDT
push progressText0B$
call PrintIfConfigBits32
call IDTInit
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

; the drives list will be 256 entries of 144 bytes each (the size of a single tDriveInfo element) plus header
push 256 * 144 + 16
push dword 1
call MemAllocate
mov [tSystem.listDrives], eax

; set up the list header
push 144
push 256
push eax
call LMListInit


; the driveLetters list will be 26 entries (A - Z) of 4 bytes each plus header
push 26 * 4 + 16
push dword 1
call MemAllocate
mov [tSystem.listDriveLetters], eax

; set all elements to 0xFFFFFFFF
push 0xFF
push 26 * 4 + 16
push eax
call MemFill

; set up the list header
push 4
push 26
push eax
call LMListInit


; the FSHandler list will be 256 entries of 4 bytes each (the size of a single 32-bit address) plus header
push 256 * 4 + 16
push dword 1
call MemAllocate
mov [tSystem.listFSHandlers], eax

; set up the list header
push 4
push 256
push eax
call LMListInit


; the partitions list will be 256 entries of 128 bytes each (the size of a single tPartitionInfo element)
; allocate memory for the list
push 256 * 128 + 16
push dword 1
call MemAllocate
mov [tSystem.listPartitions], eax

; set up the list header
push 128
push 256
push eax
call LMListInit


; the PCI handlers list will be 65536 entries of 4 bytes each (the size of a single 32-bit address)
; allocate memory for the list
push 65536 * 4 + 16
push dword 1
call MemAllocate
mov [tSystem.listPCIHandlers], eax

; set up the list header
push 4
push 65536
push eax
call LMListInit



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
call FAT16ServiceHandler

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
call PartitionEnumerate



; map partitions
; for now, we just do drive C
push progressText15$
call PrintIfConfigBits32
push 2
push 0
call PartitionMap



; init Task Manager
push progressText16$
call PrintIfConfigBits32
call TaskInit



; test load a file
push 0xFF
push 0x100000
push 0x200000
call MemFill

;push .path14$
;push .path13$
;push .path12$
;push .path11$
push .path9$
;push .path8$
;push .path7$
;push .path6$
;push .path5$
;push .path4$
;push .path3$
;push .path2$
;push .path1$
call FMFileLoad

; show if there was an error in eax from the above call
pusha
call PrintRegs32
popa

push 0
push 7
push 10
push 1
shr ecx, 4
push ecx
push edi
call PrintRAM32
jmp $

push dword 0x19000 ; length
push dword 0x200000 ; address
push .path10$ ; pathptr
call FMFileStore

; show if there was an error in eax from the above call
call PrintRegs32

jmp $

push .path7$
call FMFileDelete

; show if there was an error in eax from the above call
call PrintRegs32

mov eax, 0x200000
jmp $

.path1$											db 'c:\autoexec.bat', 0x00
.path2$											db '00:\autoexec.bat', 0x00
.path3$											db 'c:\TESTING\system\tools\items\code\fluff\nonsense\secret.txt', 0x00
.path4$											db 'x:\', 0x00
.path5$											db '00:\kernel.sys', 0x00
.path6$											db 'c:\TESTING\who.TXT', 0x00
.path7$											db 'c:\TESTING\john.TXT', 0x00
.path8$											db 'c:\TESTING\cbcfiles\pcworld\utils\logging.bas', 0x00
.path9$											db 'c:\TESTING\cbcfiles\pcworld\utils', 0x00
.path10$										db 'c:\TESTING\john2.TXT', 0x00
.path11$										db 'c:\TESTING', 0x00
.path12$										db 'c:', 0x00
.path13$										db 'c:\KERNEL.SYS', 0x00
.path14$										db 'c:\TESTING\LINcoln.TXT', 0x00




; skip this for now, it's just an experiment
; comment out the jmp to run this code
jmp PagingDone
; experimental paging setup
cli

push 0
call PageDirCreate
pop dword [PDAddr]

push 0
call PageTableCreate
pop dword [PTAddr]


; insert page table into page directory while leaving the flags alone which we just set earlier
; set up the first 4 MiB
mov ecx, dword [PDAddr]
mov eax, [ecx]
and eax, 3
mov ebx, dword [PTAddr]
or ebx, eax
or ebx, 1			; set the "present" bit
mov eax, dword [PDAddr]
mov [eax], ebx

; and now point the second 4 MiB to the first
mov ecx, dword [PDAddr]
mov eax, [ecx]
and eax, 3
mov ebx, dword [PTAddr]
or ebx, eax
or ebx, 1			; set the "present" bit
mov eax, dword [PDAddr]
add eax, 4			; this advances to the second entry
mov [eax], ebx



; turn it all on!
push dword [PDAddr]
call PageDirLoad

; enable paging
mov eax, cr0
or eax, 0x80000000
mov cr0, eax



; that's it! paging is active

; Here we will do a test write at 0x400000 - the 4 MiB mark.
; If all went well, a dump of RAM in the VirtualBox debugger should show the same data
; at both address 0x000000 and 0x400000, even though we only wrote it at 0x400000.
; How is this possible? THE MAGIC OF PAGING IS AMONG US!
mov eax, 0x00400000
mov dword [eax], 0xCAFEBEEF



; hang here so we can survey our success!
jmp $

PDAddr									dd 0x00000000
PTAddr									dd 0x00000000



PageDirCreate:
	push ebp
	mov ebp, esp

	sub esp, 4
	%define PDAddress							dword [ebp - 4]

	; get a chunk of RAM that's 4KiB in size and aligned on a 4096-byte boundary
	push 4096
	push 4096
	push 0x01
	call MemAllocateAligned
	mov PDAddress, eax

	mov ecx, 1024
	.zeroLoop:
		mov eax, 4
		mov edx, 0
		mov ebx, ecx
		dec ebx
		mul ebx
		add eax, PDAddress
		mov dword [eax], 0x00000002
	loop .zeroLoop

	mov eax, PDAddress
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret

PageTableCreate:
	push ebp
	mov ebp, esp

	sub esp, 4
	%define PTAddress							dword [ebp - 4]

	; get a chunk of RAM that's 4KiB in size and aligned on a 4096-byte boundary
	push 4096
	push 4096
	push 0x01
	call MemAllocateAligned
	mov PTAddress, eax

	mov ecx, 1024
	.zeroLoop:
		mov eax, 4
		mov edx, 0
		mov ebx, ecx
		dec ebx
		mul ebx
		add eax, PTAddress
		push eax

		mov eax, 0x1000
		mul ebx
		or eax, 3

		pop ebx
		mov dword [ebx], eax
	loop .zeroLoop

	mov eax, PTAddress
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret

pusha
call PrintRegs32
popa

PageDirLoad:

	push ebp
	mov ebp, esp

	mov eax, [ebp + 8]
	mov cr3, eax

	mov esp, ebp
	pop ebp
ret


PagingEnable:
	push ebp
	mov ebp, esp

	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax

	mov esp, ebp
	pop ebp
ret

PagingDone:





















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
progressText08$									db 'Enabling CPU debug featurtes', 0x00
progressText09$									db 'Memory list init', 0x00
progressText0A$									db 'Stack setup', 0x00
progressText0B$									db 'IDTInit', 0x00
progressText0C$									db 'Remaping PICs', 0x00
progressText0D$									db 'Initializing RTC', 0x00
progressText0E$									db 'Enabling interrupts', 0x00
progressText0F$									db 'Load system data to the info struct', 0x00
progressText10$									db 'Allocating list space', 0x00
progressText11$									db 'Initializing PS/2 driver', 0x00
progressText12$									db 'Setting up default handler addresses', 0x00
progressText13$									db 'Initializing PCI devices', 0x00
progressText14$									db 'Enumerating partitions', 0x00
progressText15$									db 'Mapping partitions', 0x00
progressText16$									db 'Initializing Task Manager', 0x00
memE820Unsupported$								db 'Could not detect memory, function unsupported', 0x00
name$											db 'Kernel Debug Menu', 0x00





section .text
; includes for system routines
%include "system/globals.asm"
%include "api/lists.asm"
%include "api/misc.asm"
%include "api/strings.asm"
%include "io/files.asm"
%include "io/serial.asm"
%include "system/CMOS.asm"
%include "system/CPU.asm"
%include "system/disks.asm"
%include "system/GDT.asm"
%include "system/hardware.asm"
%include "system/interrupts.asm"
%include "system/memory.asm"
%include "system/numbers.asm"
%include "system/PCI.asm"
%include "system/PIC.asm"
%include "system/power.asm"
%include "system/RTC.asm"
%include "system/tasks.asm"
%include "video/screen.asm"
%include "system/debug.asm"

; includes for drivers
%include "drivers/IDE Controller.asm"
%include "drivers/FAT Filesystem.asm"
%include "drivers/PS2 Controller.asm"
