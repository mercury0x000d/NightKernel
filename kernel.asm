; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; kernel.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.


extern Print32, PrintIfConfigBits16, PrintIfConfigBits32, PrintRegs32, LMListInit,\
	   PCILoadDrivers, DriverLegacyLoad, PCIInitBus, PCILoadDrivers,SetSystemAPM,\
	   APMEnable, GDTStart, MemInit, ScreenClear32, DebugMenu, MemAllocateAligned

extern kMaxLines, kBytesPerScreen, textColor, backColor, MemProbe, A20Enable,\
	   PCIProbe, IDTInit, ISRInitAll, PICInit, PICIRQDisableAll, PICIRQEnableAll,\
	   PITInit, RTCInit, SetSystemCPUID, MemAllocate, PartitionEnumerate, TaskInit, TimerWait


; [map all kernel.map]
bits 16





section .text

; set origin point to where the FreeDOS bootloader loads this code
# org 0x0600


; Clear the direction flag; nobody knows what weirdness the BIOS did before we got here.
cld


main:
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
test dword [tSystem.configBits], 000000000000000000000000000000100b
jz .stickWith25

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
mov byte [textColor], 7
mov byte [backColor], 0



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



; probe the PCI controller while we still can
push progressText05$
call PrintIfConfigBits16
call PCIProbe



; load that GDT!
push progressText06$
call PrintIfConfigBits16
lgdt [GDTStart]



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



; memory list init
push progressText08$
call PrintIfConfigBits32
call MemInit



; now that we have a temporary stack and access to all the memory addresses,
; let's allocate some RAM for the real stack
push progressText09$
call PrintIfConfigBits32

push dword [kKernelStack]
push dword 1
call MemAllocate
pop eax

mov ebx, [kKernelStack]
add eax, ebx
mov esp, eax
; push a null to stop any traces which may attempt to analyze the stack later
push 0x00000000



; set up our interrupt handlers and IDT
push progressText0A$
call PrintIfConfigBits32
call IDTInit
call ISRInitAll



; setup and remap both PICs
push progressText0B$
call PrintIfConfigBits32
call PICInit
call PICIRQDisableAll
call PICIRQEnableAll
call PITInit



; init the RTC
push progressText0C$
call PrintIfConfigBits32
call RTCInit



; let's get some interrupts firing!
push progressText0D$
call PrintIfConfigBits32
sti



; load system data into the info struct
push progressText0E$
call PrintIfConfigBits32
call SetSystemCPUID



; allocate the system lists
push progressText0F$
call PrintIfConfigBits32

; the drives list will be 256 entries of 120 bytes each (the size of a single tDriveInfo element) plus header
; 256 * 120 + 16 = 30736
; allocate memory for the list
push 30736
push dword 1
call MemAllocate
pop edi
mov [tSystem.listDrives], edi

; set up the list header
push 120
push 256
push edi
call LMListInit


; the partitions list will be 256 entries of 76 bytes each (the size of a single tPartitionInfo element)
; 256 * 76 + 16 = 19472
; allocate memory for the list
push 19472
push dword 1
call MemAllocate
pop edi
mov [tSystem.listPartitions], edi

; set up the list header
push 76
push 256
push edi
call LMListInit



; if we have a PCI controller in the first place, init the bus, find out how many PCI devices we have, and save that info to the system struct
cmp dword [tSystem.PCIVersion], 0
je .NoPCI

	; if we get here, we have PCI
	; so let's init things!
	push progressText10$
	call PrintIfConfigBits32
	call PCIInitBus

	; now load drivers for PCI devices
	push progressText11$
	call PrintIfConfigBits32
	call PCILoadDrivers
	jmp .PCIComplete

.NoPCI:
push PCIFailed$
call Print32

.PCIComplete:



; load drivers for legacy devices
push progressText12$
call PrintIfConfigBits32
call DriverLegacyLoad



; enumerate partitions
push progressText13$
call PrintIfConfigBits32
call PartitionEnumerate



; init Task Manager
push progressText14$
call PrintIfConfigBits32
call TaskInit




; skip this for now, it's just an experiment
; comment out the jmp to run this code
jmp PagingDone
; experimental paging setup
cli
PDAddr									dd 0x00000000
PTAddr									dd 0x00000000

push 0
call PageDirCreate
pop dword [PDAddr]

push 0
call PageTableCreate
pop dword [PTAddr]


; insert page table into page directory while leaving the flags alone which we just set earlier
mov ecx, dword [PDAddr]
mov eax, [ecx]
and eax, 3
mov ebx, dword [PTAddr]
or ebx, eax
or ebx, 1			; set the "present" bit
mov eax, dword [PDAddr]
mov [eax], ebx





; turn it all on!
push dword [PDAddr]
call PageDirLoad

call PagingEnable

mov eax, 0xcafebeef

; at this point, the first 

; hang here so we can survey our success!
jmp $


jmp PagingDone



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
	pop PDAddress

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

	; get a chunk of RAM as before
	push 4096
	push 4096
	push 0x01
	call MemAllocateAligned
	pop PTAddress

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






mov eax, dword [tSystem.configBits]
and eax, 000000000000000000000000000000001b
cmp eax, 000000000000000000000000000000001b
jne .SkipStartDelay
	; if we get here, we're in Debug Mode
	; wouldn't it be nice if we gave the user a moment to admire all those handy debug messages?
	push 512
	call TimerWait
.SkipStartDelay:



; clear the screen and start!
call ScreenClear32


;ScanCodeTestLoop:
;	push 0
;	call KeyWait
;	pop eax
;
;	inc byte [cursorY]
;	call PrintRegs32
;
;jmp ScanCodeTestLoop



;push Task1
;call TaskNew
;pop eax
;mov ebx, 0xBEEFCA1F
;mov ecx, 0xBEEFCA1F
;mov edx, 0xBEEFCA1F
;call PrintRegs32
;
;
;push Task2
;call TaskNew
;pop eax
;mov ebx, 0xBEEFCA1F
;mov ecx, 0xBEEFCA1F
;mov edx, 0xBEEFCA1F
;call PrintRegs32
;
;jmp $

; enter the infinite loop which runs the kernel
InfiniteLoop:
	; do stuff here, i guess... :)

	; enter the Debug Menu if appropriate
	mov eax, [tSystem.configBits]
	and eax, 000000000000000000000000000000001b
	cmp eax, 000000000000000000000000000000001b
	jne .SkipDebugMenu
		call DebugMenu
	.SkipDebugMenu:

jmp InfiniteLoop



Task1:
	inc dword [0x200000]
jmp Task1


Task2:
	inc dword [0x200010]
jmp Task1

section .data
progressText01$									db 'Probing BIOS memory map', 0x00
progressText02$									db 'Beginning A20 enable procedure', 0x00
progressText03$									db 'SetSystemAPM', 0x00
progressText04$									db 'APMEnable', 0x00
progressText05$									db 'LoadGDT', 0x00
progressText06$									db 'Probing PCI controller', 0x00
progressText07$									db 'Entering Protected Mode', 0x00
progressText08$									db 'Memory list init', 0x00
progressText09$									db 'Stack setup', 0x00
progressText0A$									db 'IDTInit', 0x00
progressText0B$									db 'Remaping PICs', 0x00
progressText0C$									db 'Initializing RTC', 0x00
progressText0D$									db 'Enabling interrupts', 0x00
progressText0E$									db 'Load system data to the info struct', 0x00
progressText0F$									db 'Allocating list space', 0x00
progressText10$									db 'Initializing PCI bus', 0x00
progressText11$									db 'Loading PCI drivers', 0x00
progressText12$									db 'Loading legacy device drivers', 0x00
progressText13$									db 'Enumerating partitions', 0x00
progressText14$									db 'Initializing Task Manager', 0x00
memE820Unsupported$								db 'Could not detect memory, function unsupported', 0x00
PCIFailed$										db 'PCI Controller not detected', 0x00


section .text
; includes for system routines
%include "include/globals.inc"
;%include "api/misc.asm"
;%include "api/lists.asm"
;%include "api/strings.asm"
;%include "io/ps2.asm"
;%include "io/serial.asm"
;%include "system/cmos.asm"
;%include "system/gdt.asm"
;%include "system/hardware.asm"
;%include "system/interrupts.asm"
;%include "system/memory.asm"
;%include "system/partitions.asm"
;%include "system/pci.asm"
;%include "system/pic.asm"
;%include "system/power.asm"
;%include "video/screen.asm"
;%include "system/debug.asm"



; includes for drivers
section .text
global DriverSpaceStart
DriverSpaceStart:
;%include "drivers/ATA Controller.asm"
;#%include "drivers/FAT12.asm"
;#%include "drivers/PS2 Controller.asm"
;%include "drivers/FAT16Small.asm"
;%include "drivers/FAT16Large.asm"
;%include "drivers/FAT32.asm"
DriverSpaceEnd:
