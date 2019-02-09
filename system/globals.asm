; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; globals.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; vars, konstants, 'n' such
kTrue											dd 0x11111111
kFalse											dd 0x00000000
kKernelStack									dd 8192
kPrintText$										times 256 db 0x00
kDriverSignature$								db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05



; arrays
kKeyTable:										db '  1234567890-=  qwertyuiop[]  asdfghjkl; ` \zxcvbnm,0/ *               789-456+1230.  '



; strucTures
tSystem:
	.copyright$									db 'Night Kernel, Copyright 1995 - 2019', 0x00
	.versionMajor								db 0x00
	.versionMinor								db 0x15
	.memoryInstalledBytes						dd 0x00000000
	.memoryInitialAvailableBytes				dd 0x00000000
	.memoryCurrentAvailableBytes				dd 0x00000000
	.memoryBlockAddress							dd 0x00000000
	.hours										db 0x00
	.minutes									db 0x00
	.seconds									db 0x00
	.ticks										db 0x00
	.century									db 0x00
	.year										db 0x00
	.month										db 0x00
	.day										db 0x00
	.secondsSinceBoot							dd 0x00000000
	.ticksSinceBoot								dd 0x00000000
	.delayValue									dd 0x00000000
	.lastError									dd 0x00000000
	.keyboardType								dw 0x0000
	.multicoreAvailable							db 0x00
	.CPUIDVendor$								times 16 db 0x00
	.CPUIDBrand$								times 64 db 0x00
	.CPUIDLargestBasicQuery						dd 0x00000000
	.CPUIDLargestExtendedQuery					dd 0x00000000
	.APMVersionMajor							db 0x00
	.APMVersionMinor							db 0x00
	.APMFeatures								dw 0x0000
	.mouseAvailable								db 0x00
	.mouseButtonCount							db 0x00
	.mouseID									db 0x00
	.mouseWheelPresent							db 0x00
	.mouseButtons								db 0x00
	.mouseX										dw 0x0000
	.mouseY										dw 0x0000
	.mouseZ										dw 0x0000
	.mouseXLimit								dd 0x00000000
	.mouseYLimit								dd 0x00000000
	.mousePacketByteSize						db 0x00
	.mousePacketByteCount						db 0x00
	.mousePacketByte1							db 0x00
	.mousePacketByte2							db 0x00
	.mousePacketByte3							db 0x00
	.mousePacketByte4							db 0x00
	.configBitsHint$							db 'ConfigBits'
	.configBits									dd 00000000000000000000000000000111b
	.listDrives									dd 0x00000000
	.listMemory									dd 0x00000000
	.listPartitions								dd 0x00000000
	.listPCIDevices								dd 0x00000000				; will be zero if no PCI support
	.PCIDeviceCount								dd 0x00000000

; tDriveInfo, for the drives list (120 bytes)
%define tDriveInfo.ATABasePort					(esi + 00)
%define tDriveInfo.ATADeviceNumber				(esi + 04)
%define tDriveInfo.deviceFlags					(esi + 08)
%define tDriveInfo.cacheAddress					(esi + 12)
%define tDriveInfo.readSector					(esi + 16)
%define tDriveInfo.writeSector					(esi + 20)
%define tDriveInfo.model						(esi + 24)		; model is 64 bytes
%define tDriveInfo.serial						(esi + 88)		; serial is 32 bytes

; tMemoryInfo, for the physical memory allocator to track blocks
%define tMemInfo.address						(esi + 00)
%define tMemInfo.size							(esi + 04)
%define tMemInfo.task							(esi + 08)

; tPartitionInfo, for the partitions list (80 bytes)
%define tPartitionInfo.ATAbasePort				(esi + 00)
%define tPartitionInfo.ATAdevice				(esi + 04)
%define tPartitionInfo.attributes				(esi + 08)
%define tPartitionInfo.startingCHS				(esi + 12)
%define tPartitionInfo.endingCHS				(esi + 16)
%define tPartitionInfo.systemID					(esi + 20)
%define tPartitionInfo.startingLBA				(esi + 24)
%define tPartitionInfo.sectorCount				(esi + 28)
%define tPartitionInfo.driveListNumber			(esi + 32)
%define tPartitionInfo.readSector				(esi + 36)
%define tPartitionInfo.writeSector				(esi + 40)
%define tPartitionInfo.fileLoad					(esi + 44)
%define tPartitionInfo.fileSave					(esi + 48)



; random infos follow...



; Memory Map (obsolete?)
; Start				End				Size						Description
; 0x00000000		0x000003FF		1 KiB						interrupt vector table
; 0x00000400		0x000004FF		256 bytes					BIOS data area (remapped here from CMOS)
; 0x00000500		0x000005FF		256 bytes					temporary stack
; 0x00000600		0x00007BFF		30207 bytes (29.49 KiB)		kernel space (kernel is loaded here by FreeDOS bootloader)
; 0x00007C00		0x00007DFF		512 bytes					bootloader (copied here by BIOS, can be overwritten)
; 0x00007E00		0x0009FBFF		622080 bytes (607.50 KiB)	available, unused
; 0x0009FC00		0x0009FFFF		1 KiB						extended BIOS data area
; 0x000A0000		0x000AFFFF		64 KiB						video buffer for EGA/VGA graphics modes
; 0x000B0000		0x000B7FFF		32 KiB						video buffer for EGA/VGA graphics modes
; 0x000B8000		0x000BFFFF		32 KiB						video buffer for color text and CGA graphics
; 0x000C0000		0x000DFFFF		128 KiB						device-mounted ROMs
; 0x000E0000		0x0010FFEF		196591 bytes (191.98 KiB)	BIOS ROM



; Result Codes for API routines (needs addressed)
; 0xF000			Success, no error
; 0xF001			Value specified is too low
; 0xF002			Value specified is too high
; 0xFF00			PS2 Controller write command timeout
; 0xFF01			PS2 Controller write data timeout
; 0xFF02			PS2 Controller read data timeout



; Event Codes (needs addressed)
; Note - Event codes 80 - FF are reserved for software and interprocess communication
; 00				Null (nothing is waiting in the queue)
; 01				Key down
; 02				Key up
; 03				Mouse move
; 04				Mouse button down
; 05				Mouse button up
; 06				Mouse wheel move
; 20				Serial input received
; 40				Application is losing focus
; 41				Application is gaining focus
