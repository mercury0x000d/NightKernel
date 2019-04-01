; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; Kernel.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; here's where all the magic happens :)

; Note: Any call to a kernel (or system library) function may destroy the
; contents of eax, ebx, ecx, edx, edi and esi.



[map all kernel.map]
bits 16



; set origin point to where the FreeDOS bootloader loads this code
org 0x0600

; clear the direction flag and turn off interrupts
cld
cli


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



; get that good ol' APM info
push progressText02$
call PrintIfConfigBits16
call SetSystemAPM



; enable the APM interface
push progressText03$
call PrintIfConfigBits16
call APMEnable



; probe the PCI controller while we still can
push progressText10$
call PrintIfConfigBits16
call PCIProbe



; load that GDT!
push progressText04$
call PrintIfConfigBits16
lgdt [GDTStart]



; enter protected mode. YAY!
push progressText05$
call PrintIfConfigBits16
mov eax, cr0
or eax, 00000001b
mov cr0, eax

; jump to start the kernel in 32-bit mode
jmp 0x08:KernelStart

bits 32

KernelStart:
; init the registers, including the temporary stack
mov ax, 0x0010
mov ds, ax
mov es, ax
mov ss, ax
mov esp, 0x0009FB00



; enable the A20 line - one of the things we require for operation
push progressText06$
call PrintIfConfigBits32
call A20Enable



; memory list init
push progressText07$
call PrintIfConfigBits32
call MemInit



; now that we have a temporary stack and access to all the memory addresses,
; let's allocate some RAM for the real stack
push progressText08$
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
push progressText09$
call PrintIfConfigBits32
call IDTInit
call ISRInitAll



; setup and remap both PICs
push progressText0A$
call PrintIfConfigBits32
call PICInit
call PICDisableIRQs
call PICUnmaskAll
call PITInit



; load system data into the info struct
push progressText0B$
call PrintIfConfigBits32
call SetSystemRTC							; load the RTC values into the system struct
call SetSystemCPUID							; set some info from the CPU into the system struct
call SetSystemCPUSpeed						; write the CPU speed info to the system struct



; setup that mickey!
push progressText0C$
call PrintIfConfigBits32
call MouseInit



; setup keyboard
push progressText0D$
call PrintIfConfigBits32
call KeyboardInit



; allocate the system lists
push progressText0E$
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



; let's get some interrupts firing!
push progressText0F$
call PrintIfConfigBits32
sti



; if we have a PCI controller in the first place, find out how many PCI devices we have and save that info to the system struct
cmp dword [tSystem.PCIVersion], 0
je .NoPCI

	; if we get here, we have PCI
	; so let's init things!
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
call DriverLegacyLoad

; enumerate partitions
call PartitionEnumerate





; clear the screen and start!
push 256
call TimerWait
call ScreenClear32



; enter the infinite loop which runs the kernel
InfiniteLoop:
	; do stuff here, i guess... :)

	mov eax, [tSystem.configBits]
	and eax, 000000000000000000000000000000001b
	cmp eax, 000000000000000000000000000000001b
	jne .SkipDebugMenu

	call DebugMenu

	.SkipDebugMenu:
jmp InfiniteLoop

progressText01$									db 'Probing BIOS memory map', 0x00
progressText02$									db 'SetSystemAPM', 0x00
progressText03$									db 'APMEnable', 0x00
progressText04$									db 'LoadGDT', 0x00
progressText05$									db 'Entering Protected Mode', 0x00
progressText06$									db 'A20Enable', 0x00
progressText07$									db 'Memory list init', 0x00
progressText08$									db 'Stack setup', 0x00
progressText09$									db 'IDTInit', 0x00
progressText0A$									db 'Remaping PICs', 0x00
progressText0B$									db 'Load system data to the info struct', 0x00
progressText0C$									db 'MouseInit', 0x00
progressText0D$									db 'KeyboardInit', 0x00
progressText0E$									db 'Allocating list space', 0x00
progressText0F$									db 'Enabling interrupts', 0x00
progressText10$									db 'Initializing PCI bus', 0x00
progressText11$									db 'Loading drivers', 0x00
memE820Unsupported$								db 'Could not detect memory, function unsupported', 0x00
PCIFailed$										db 'PCI Controller not detected', 0x00



; includes for system routines
;%include "system/globals.asm"
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
%include "video/screen.asm"
%include "system/debug.asm"



; includes for drivers
DriverSpaceStart:
%include "drivers/ATA Controller.asm"
%include "drivers/FAT12.asm"
;%include "drivers/FAT16Small.asm"
;%include "drivers/FAT16Large.asm"
;%include "drivers/FAT32.asm"
DriverSpaceEnd:
