; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; includes/globals.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





section .data
; vars, konstants, 'n' such
kTrue											dd 0x00000001
kFalse											dd 0x00000000
kKernelStack									dd 8192
kPrintText$										times 256 db 0x00
kDriverSignature$								db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05





; strucTures
tSystem:
	.configBitsHint$							db 'ConfigBits'
	.configBits									dd 00000000000000000000000000000111b
	.copyright$									db 'Night Kernel, Copyright 1995 - 2019', 0x00
	.versionMajor								db 0x00
	.versionMinor								db 0x19
	.ticksSinceBoot								dd 0x00000000
	.multicoreAvailable							db 0x00
	.CPUIDVendor$								times 16 db 0x00
	.CPUIDBrand$								times 64 db 0x00
	.CPUIDLargestBasicQuery						dd 0x00000000
	.CPUIDLargestExtendedQuery					dd 0x00000000
	.APMVersionMajor							db 0x00
	.APMVersionMinor							db 0x00
	.APMFeatures								dw 0x0000

section .bss
	.listDrives									resd 1
	.listMemory									resd 1
	.listPartitions								resd 1
	.listPCIDevices								resd 1
	.listTasks									resd 1
	.memoryInstalledBytes						resd 1
	.memoryInitialAvailableBytes				resd 1
	.memoryListReservedSpace					resd 1
	.PCIDeviceCount								resd 1
	.PCIVersion									resd 1
	.PCICapabilities							resd 1
	.PS2ControllerConfig						resb 1
	.PS2ControllerPort1Status					resb 1
	.PS2ControllerPort2Status					resb 1
	.PS2ControllerDeviceID1						resw 1
	.PS2ControllerDeviceID2						resw 1
	.mouseButtonCount							resb 1
	.mouseButtons								resb 1
	.mousePacketByteSize						resb 1
	.mousePacketByteCount						resb 1
	.mousePacketByte0							resb 1
	.mousePacketByte1							resb 1
	.mousePacketByte2							resb 1
	.mousePacketByte3							resb 1
	.mouseWheelPresent							resb 1
	.mouseX										resw 1
	.mouseXLimit								resw 1
	.mouseY										resw 1
	.mouseYLimit								resw 1
	.mouseZ										resw 1
	.RTCUpdateHandlerAddress					resd 1
	.RTCStatusRegisterB							resb 1
	.hours										resb 1
	.minutes									resb 1
	.seconds									resb 1
	.year										resb 1
	.month										resb 1
	.day										resb 1





; tDriveInfo, for the drives list (120 bytes)
%define tDriveInfo.ATABasePort					(esi + 00)
%define tDriveInfo.ATADeviceNumber				(esi + 04)
%define tDriveInfo.deviceFlags					(esi + 08)
%define tDriveInfo.cacheAddress					(esi + 12)
%define tDriveInfo.readSector					(esi + 16)
%define tDriveInfo.writeSector					(esi + 20)
%define tDriveInfo.model						(esi + 24)		; model is 64 bytes
%define tDriveInfo.serial						(esi + 88)		; serial is 32 bytes





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

; Maximum kernel size loadable by FreeDOS loader: 137285 bytes. Yes, I tested it.
