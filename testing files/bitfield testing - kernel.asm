; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; bitfield testing - kernel.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; boy, the kernel needs a lot of headers to start! :D
%include "include/kernelDefines.inc"

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
%include "include/numbers.inc"
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
	mov dword [kBytesPerScreen], 8000

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



; copy the BIOS memory map to 8000:0 (0x80000) for later parsing
push progressText01$
call PrintIfConfigBits16

mov bx, 0x8000
mov es, bx
call MemMapCopy
xor bx, bx
mov es, bx

; see if there was an error
cmp edx, kErrNone
je .MemProbeOK
	; do a fatal error here, 16-bit style
	mov byte [gTextColor], 0
	mov byte [gBackColor], 4
	push fatalE820Unsupported$
	call Print16
.MemProbeOK:

; save the returned size of the memory map
and eax, 0x0000FFFF
mov dword [tSystem.memoryBIOSMapEntryCount], eax



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
mov esp, 0x0009fb00



; hello world!
call PrintCopyright
call PrintVerison



; probe CPU
push progressText08$
call PrintIfConfigBits32
call CPUProbe



; set up any CPU features we'll need
push progressText09$
call PrintIfConfigBits32
call CPUInit



; turn on CPU debug extensions
; is it faster to leave these off?
push progressText0A$
call PrintIfConfigBits32
call DebugCPUFeaturesEnable



; memory list init
push progressText0B$
call PrintIfConfigBits32
call MemInit



; now that we have a temporary stack and access to all the memory addresses,
; let's allocate some RAM for the real stack
push progressText0C$
call PrintIfConfigBits32
call MemAllocate

; see if there was an error
cmp edx, kErrNone
je .StackAllocOK
	push fatalKernelStackMemAlloc$
	call Fail
.StackAllocOK:

add eax, 4096
mov esp, eax
; push a null to stop any traces which may attempt to analyze the stack later
push 0x00000000



; set up our interrupt handlers and IDT
push progressText0D$
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
push progressText0E$
call PrintIfConfigBits32
call PICInit
call PICIRQDisableAll
call PICIRQEnableAll
call PITInit



; init the RTC
push progressText0F$
call PrintIfConfigBits32
call RTCInit



; let's get some interrupts firing!
push progressText10$
call PrintIfConfigBits32
sti



; allocate the system lists
push progressText11$
call PrintIfConfigBits32
call KernelInitLists

; see if there was an error
cmp edx, kErrNone
je .ListInitOK
	push fatalListMemAlloc$
	call Fail
.ListInitOK:



; init PS/2 driver
push progressText12$
call PrintIfConfigBits32
call PS2ControllerInit



; set up default handlers
push progressText13$
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
push progressText14$
call PrintIfConfigBits32
call PCIDeviceInitAll



; enumerate partitions
push progressText15$
call PrintIfConfigBits32
call SMPartitionEnumerate


; map partitions
; for now, we just do drive C
push progressText16$
call PrintIfConfigBits32
push 2
push 0
call SMPartitionMap



; init Task Manager
push progressText17$
call PrintIfConfigBits32
call TaskInit



; initialize paging
push progressText18$
call PrintIfConfigBits32
call PagingInit





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











; code testing area

push 130
push 0x500
call LMBitfieldInit



push 0
push 0x500
call LMBitSet

push 5
push 0x500
call LMBitSet

push 8
push 0x500
call LMBitSet

push 99
push 0x500
call LMBitSet

push 99
push 0x500
call LMBitSet

push 10
push 0x500
call LMBitClear

push 10
push 0x500
call LMBitFlip

push 10
push 0x500
call LMBitFlip

push 11
push 0x500
call LMBitFlip

push 0
push 0x500
call LMBitSet

push 99
push 0x500
call LMBitSet



mov ecx, [0x504]
call PrintRegs32 ; should be 0x05 here


push 2
push 0
push 20
push 1
push 4
push 0x500
call PrintRAM32



push 29
push 29
push 0x500
call LMBitSetRange ; should be 0x06 here
mov ecx, [0x504]
call PrintRegs32

push 33
push 31
push 0x500
call LMBitSetRange ; should be 0x09 here
mov ecx, [0x504]
call PrintRegs32

push 67
push 42
push 0x500
call LMBitSetRange ; should be 0x23 here
mov ecx, [0x504]
call PrintRegs32

push 53
push 46
push 0x500
call LMBitClearRange ; should be 0x1B here
mov ecx, [0x504]
call PrintRegs32

push 127
push 0
push 0x500
call LMBitFlipRange ; should be 0x65 here
mov ecx, [0x504]
call PrintRegs32

push 127
push 64
push 0x500
call LMBitClearRange ; should be 0x2A here
mov ecx, [0x504]
call PrintRegs32

push 63
push 0
push 0x500
call LMBitClearRange ; should be 0x00 here
mov ecx, [0x504]
call PrintRegs32

push 127
push 0
push 0x500
call LMBitClearRange ; should be 0x00 here
mov ecx, [0x504]
call PrintRegs32



push 3
push 0
push 26
push 1
push 4
push 0x500
call PrintRAM32
jmp $

; 21 09 00 a0 03 3c c0 ff-0f 00 00 00 08 00 00 00
; de f6 ff 5f fc c3 3f 00-f0 ff ff ff f7 ff ff ff

; 00 - 07	0
; 08 - 15	1
; 16 - 23	2
; 24 - 31	3
; 32 - 39	4
; 40 - 47	5
; 48 - 55	6
; 56 - 63	7
; 64 - 71	8































section .data
progressText00$									db 'Night Kernel', 0x00
progressText01$									db 'Shadowing BIOS memory map', 0x00
progressText02$									db 'Beginning A20 enable procedure', 0x00
progressText03$									db 'SetSystemAPM', 0x00
progressText04$									db 'APMEnable', 0x00
progressText05$									db 'LoadGDT', 0x00
progressText06$									db 'Probing PCI controller', 0x00
progressText07$									db 'Entering Protected Mode', 0x00
progressText08$									db 'Probing CPU features', 0x00
progressText09$									db 'Initializing CPU features', 0x00
progressText0A$									db 'Enabling CPU debug extensions', 0x00
progressText0B$									db 'Memory list init', 0x00
progressText0C$									db 'Stack setup', 0x00
progressText0D$									db 'IDTInit', 0x00
progressText0E$									db 'Remaping PICs', 0x00
progressText0F$									db 'Initializing RTC', 0x00
progressText10$									db 'Enabling interrupts', 0x00
progressText11$									db 'Allocating system lists', 0x00
progressText12$									db 'Initializing PS/2 driver', 0x00
progressText13$									db 'Setting up default handler addresses', 0x00
progressText14$									db 'Initializing PCI devices', 0x00
progressText15$									db 'Enumerating partitions', 0x00
progressText16$									db 'Mapping partitions', 0x00
progressText17$									db 'Initializing Task Manager', 0x00
progressText18$									db 'Initializing CPU paging features', 0x00
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

	; allocate local variables
	sub esp, 4
	%define address								dword [ebp - 4]


	; the drives list will be 256 entries of tDriveInfo structs, plus header (256 * tDriveInfo_size + 16)
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPtrDrives], eax

	; set up the list header
	push tDriveInfo_size
	push dword 256
	push dword [tSystem.listPtrDrives]
	call LMListInit

	; to hold this list, we need 7 more pages of RAM
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate



	; the driveLetters list will be 26 entries (A - Z) of 4 bytes each plus header (26 * 4 + 16)
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPtrDriveLetters], eax

	; set all elements to 0xFFFFFFFF
	push dword 0xFF
	push dword 26 * 4 + 16
	push eax
	call MemFill


	; set up the list header
	push dword 4
	push dword 26
	push dword [tSystem.listPtrDriveLetters]
	call LMListInit



	; the FSHandler list will be 256 entries of 4 bytes each (the size of a single 32-bit address) plus header (256 * 4 + 16)
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPtrFSHandlers], eax

	; set up the list header
	push dword 4
	push dword 256
	push eax
	call LMListInit



	; the partitions list will be 256 entries of tPartitionInfo structs, plus header (256 * tPartitionInfo_size + 16)
	; allocate memory for the list
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPtrPartitions], eax

	; set up the list header
	push dword tPartitionInfo_size
	push dword 256
	push eax
	call LMListInit

	; to hold this list, we need 8 more pages of RAM
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate
	call MemAllocate


	; the PCI handlers list will be 65536 entries of 4 bytes (the size of a single 32-bit address) each (65536 * 4 + 16)
	; allocate memory for the list
	call MemAllocate
	cmp edx, kErrNone
	jne .Exit
	mov [tSystem.listPtrPCIHandlers], eax

	; set up the list header
	push dword 4
	push dword 65536
	push eax
	call LMListInit

	; to hold this list, we need 64 more pages of RAM
	mov ecx, 64
	.AllocateLoop:
		call MemAllocate
	loop .AllocateLoop


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
