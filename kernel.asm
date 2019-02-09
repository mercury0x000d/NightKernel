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
call MemoryInit



; get that good ol' APM info
push progressText02$
call PrintIfConfigBits16
call SetSystemAPM



; enable the APM interface
push progressText03$
call PrintIfConfigBits16
call APMEnable



; load that GDT
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



; now that we have a temporary stack and access to all the memory addresses,
; let's allocate some RAM for the real stack
push progressText07$
call PrintIfConfigBits32
push dword [kKernelStack]
call MemAllocate
pop eax
mov ebx, [kKernelStack]
add eax, ebx
mov esp, eax
; push a null to stop any traces which may attempt to analyze the stack later
push 0x00000000


; set up our interrupt handlers and IDT
push progressText08$
call PrintIfConfigBits32
call IDTInit
call ISRInitAll



; setup and remap both PICs
push progressText09$
call PrintIfConfigBits32
call PICInit
call PICDisableIRQs
call PICUnmaskAll
call PITInit



; load system data into the info struct
push progressText0A$
call PrintIfConfigBits32
call SetSystemRTC							; load the RTC values into the system struct
call SetSystemCPUID							; set some info from the CPU into the system struct
call SetSystemCPUSpeed						; write the CPU speed info to the system struct



; setup that mickey!
push progressText0B$
call PrintIfConfigBits32
call MouseInit



; setup keyboard
push progressText0C$
call PrintIfConfigBits32
call KeyboardInit



; allocate the system lists
push progressText0D$
call PrintIfConfigBits32

; the drives list will be 256 entries of 120 bytes each (the size of a single tDriveInfo element) plus header
; 256 * 120 + 16 = 30736
; allocate memory for the list
push 30736
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
call MemAllocate
pop edi
mov [tSystem.listPartitions], edi

; set up the list header
push 76
push 256
push edi
call LMListInit



; let's get some interrupts firing!
push progressText0E$
call PrintIfConfigBits32
sti



; find out how many PCI devices we have and save that info to the system struct
push progressText0F$
call PrintIfConfigBits32
push 0
call PCIDetect
pop eax
cmp eax, [kTrue]
jne .PCIFail

call PCIInitBus
jmp .PCISkip

.PCIFail:
push PCIFailed$
call Print32
jmp .PCISkip

.PCISkip:


; load drivers for PCI devices
push progressText10$
call PrintIfConfigBits32
call PCILoadDrivers

; load drivers for legacy devices
call DriverLegacyLoad

; enumerate partitions
call PartitionEnumerate



; WELCOME TO THE CODE TESTING AREA
; AUTHORIZED PERSONNEL ONLY
; DISPLAY ID TAGS AT ALL TIMES
; PLEASE ENJOY YOUR STAY

; remaining for reentrancy: StringBuild()




;; ATA sector testing
;
;push 0x200000
;push 1
;push 303030
;push 0
;push 0x01F0
;call C01SectorWriteLBA28PIO
;
;push 0x300000
;push 1
;push 303030
;push 0
;push 0x01F0
;call C01SectorReadLBA28PIO
;
;push 3
;push 0x200000
;call PrintRAM32
;
;push 8
;push 0x20023E
;call PrintRAM32
;
;push 32
;push 0x300000
;call PrintRAM32
;
;
;jmp $





;; ATAPI sector read testing
;push 0x200000
;push 1
;push 0x00000010
;push 0
;push 0x0170
;call C01ATAPISectorReadPIO
;
;push 0x300000
;push 1
;push 0x00000011
;push 0
;push 0x0170
;call C01ATAPISectorReadPIO




;; StringAppend/Prepend testing
;push 65
;push string$
;call StringCharPrepend
;
;push 66
;push string$
;call StringCharPrepend
;
;push 67
;push string$
;call StringCharPrepend
;
;push string$
;call Print32
;
;jmp $
;
;string$							db 'Four score and seven years ago', 0x00





;; StringTruncate testing
;push 13
;push string$
;call StringTruncateLeft
;
;push string$
;call Print32
;
;jmp $
;
;string$							db 'Four score and seven years ago', 0x00





;; StringPad testing
;push 40
;push 65
;push string$
;call StringPadLeft
;
;push string$
;call Print32
;
;jmp $
;
;string$							db 'Four score and seven years ago', 0x00
;buffer$							times 128 db 0x00





;; StringFindFirstMatch testing
;push matchlist$
;push string$
;call StringFindFirstMatch
;pop eax
;call PrintRegs32
;jmp $
;
;string$							db 'Four score and seven years ago', 0x00
;matchlist$							db 'xaeiou', 0x00





;; GDT routine tests
;push 0x0000000F
;push 0x000000FA
;push 0x00088888
;push 0x01234567
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTBuild

;push 0x12345678
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTSetBaseAddress
;
;push 0x95327
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTSetLimitAddress
;
;push 0x22
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTSetAccessFlags
;
;push 0x88
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTSetSizeFlags
;
;
;
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTGetBaseAddress
;pop eax
;call PrintRegs32
;
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTGetLimitAddress
;pop eax
;call PrintRegs32
;
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTGetAccessFlags
;pop eax
;call PrintRegs32
;
;mov eax, GDTStart
;add eax, 24
;push eax
;call GDTGetSizeFlags
;pop eax
;call PrintRegs32
;jmp $




;; GetWord testing
;call ScreenClear32
;
;push stringA$
;call Print32
;
;push stringB$
;call Print32
;
;
;push sep$
;push string$
;call StringWordCount
;pop ecx
;
;call PrintRegs32
;
;mov edx, 0
;.wordloop:
;	inc edx
;	pusha
;
;	push scratch$
;	push edx
;	push sep$
;	push string$
;	call StringWordGet
;
;	push 0x27
;	push scratch$
;	call StringCharPrepend
;
;	push 0x27
;	push scratch$
;	call StringCharAppend
;
;	push scratch$
;	call Print32
;
;	popa
;loop .wordloop
;.done:
;jmp $
;string$							db 'Shopping list for dinner: oranges, grapes, apples, screwdrivers.', 0x00
;sep$							db ', .:', 0x00
;stringA$						db 'The string is: "Shopping list for dinner: oranges, grapes, apples, screwdrivers."', 0x00
;stringB$						db 'The separator is: ", .:"', 0x00
;scratch$						times 32 db 0x00





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



progressText01$									db 'MemoryInit', 0x00
progressText02$									db 'SetSystemAPM', 0x00
progressText03$									db 'APMEnable', 0x00
progressText04$									db 'LoadGDT', 0x00
progressText05$									db 'Entering Protected Mode', 0x00
progressText06$									db 'A20Enable', 0x00
progressText07$									db 'Stack setup', 0x00
progressText08$									db 'IDTInit', 0x00
progressText09$									db 'Remaping PICs', 0x00
progressText0A$									db 'Load system data to the info struct', 0x00
progressText0B$									db 'MouseInit', 0x00
progressText0C$									db 'KeyboardInit', 0x00
progressText0D$									db 'Allocating list space', 0x00
progressText0E$									db 'Enabling interrupts', 0x00
progressText0F$									db 'Initializing PCI bus', 0x00
progressText10$									db 'Loading drivers', 0x00
memE820Unsupported$								db 'Could not detect memory, function unsupported', 0x00
PCIFailed$										db 'PCI Controller not detected', 0x00



; includes for system routines
%include "system/globals.asm"
%include "api/misc.asm"
%include "api/lists.asm"
%include "api/strings.asm"
%include "io/ps2.asm"
%include "io/serial.asm"
%include "system/cmos.asm"
%include "system/debug.asm"
%include "system/gdt.asm"
%include "system/hardware.asm"
%include "system/interrupts.asm"
%include "system/memory.asm"
%include "system/partitions.asm"
%include "system/pci.asm"
%include "system/pic.asm"
%include "system/power.asm"
%include "video/screen.asm"



; includes for drivers
DriverSpaceStart:
%include "drivers/ATA Controller.asm"
DriverSpaceEnd:
