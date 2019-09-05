; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; globals.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; a define for use by Xenops, the version-updating tool with the most awesome name ever :D
%define BUILD 1397





section .data



kKernelStack									dd 8192
kDriverSignature$								db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05





; strucTures
tSystem:
	.configBitsHint$							db 'ConfigBits'
	.configBits									dd 00000000000000000000000000000111b
	.copyright$									db 'Night Kernel, Copyright 2015 - 2019', 0x00
	.versionMajor								db 0x00
	.versionMinor								db 0x1D
	.versionBuild								dw BUILD
	.ticksSinceBoot								dd 0x00000000
	.currentTask								dd 0x00000000
	.currentTaskSlotAddress						dd 0x00000000
	.taskingEnable								db 0x00
	.taskStackSize								dd 1024		; a 1 KiB stack is almost guaranteed to be too small in the future
	.taskKernelStackSize						dd 1024
	.multicoreAvailable							db 0x00
	.CPUIDVendor$								times 16 db 0x00
	.CPUIDBrand$								times 64 db 0x00
	.CPUIDLargestBasicQuery						dd 0x00000000
	.CPUIDLargestExtendedQuery					dd 0x00000000
	.APMVersionMajor							db 0x00
	.APMVersionMinor							db 0x00
	.APMFeatures								dw 0x0000
	.mouseButtonCount							db 0x00
	.mouseButtons								db 0x00
	.mousePacketByteSize						db 0x00
	.mousePacketByteCount						db 0x00
	.mousePacketByte0							db 0x00
	.mousePacketByte1							db 0x00
	.mousePacketByte2							db 0x00
	.mousePacketByte3							db 0x00
	.mouseWheelPresent							db 0x00
	.mouseX										dw 0x0000
	.mouseXLimit								dw 0x0000
	.mouseY										dw 0x0000
	.mouseYLimit								dw 0x0000
	.mouseZ										dw 0x0000

section .bss
	.listDrives									resd 1
	.listDriveLetters							resd 1
	.listFSHandlers								resd 1
	.listMemory									resd 1
	.listPartitions								resd 1
	.listPCIHandlers							resd 1
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
	.RTCUpdateHandlerAddress					resd 1
	.RTCStatusRegisterB							resb 1
	.hours										resb 1
	.minutes									resb 1
	.seconds									resb 1
	.year										resb 1
	.month										resb 1
	.day										resb 1

; tDriveInfo, for the drives list (144 bytes)
%define tDriveInfo.model						00				; model is 64 bytes
%define tDriveInfo.serial						64				; serial is 32 bytes
%define tDriveInfo.PCIClass						(esi + 96)
%define tDriveInfo.PCISubclass					(esi + 100)
%define tDriveInfo.PCIBus						(esi + 104)
%define tDriveInfo.PCIDevice					(esi + 108)
%define tDriveInfo.PCIFunction					(esi + 112)
%define tDriveInfo.cacheAddress					(esi + 116)
%define tDriveInfo.deviceFlags					(esi + 120)
%define tDriveInfo.ATABasePort					(esi + 124)
%define tDriveInfo.ATAControlPort				(esi + 128)
%define tDriveInfo.ATADeviceNumber				(esi + 132)
%define tDriveInfo.reserved1					(esi + 136)
%define tDriveInfo.reserved2					(esi + 140)

; tTaskInfo struct, used to... *GASP* manage tasks (96 bytes)
%define tTaskInfo.pageDirAddress				(esi + 00)
%define tTaskInfo.entryPoint					(esi + 04)
%define tTaskInfo.esp							(esi + 08)
%define tTaskInfo.esp0							(esi + 12)
%define tTaskInfo.stackAddress					(esi + 16)
%define tTaskInfo.kernelStackAddress			(esi + 20)
%define tTaskInfo.priority						(esi + 24)
%define tTaskInfo.turnsRemaining				(esi + 25)
%define tTaskInfo.unused						(esi + 26)
%define tTaskInfo.switchInLow					(esi + 28)
%define tTaskInfo.switchInHigh					(esi + 32)
%define tTaskInfo.cycleCountLow					(esi + 36)
%define tTaskInfo.cycleCountHigh				(esi + 40)
%define tTaskInfo.spawnedBy						(esi + 44)
%define tTaskInfo.taskFlags						(esi + 48)
%define tTaskInfo.name							(esi + 64)		; name field is 16 bytes (for now, may need to expand)

; tPartitionInfo, for the partitions list (128 bytes)
%define tPartitionInfo.PCIClass					(esi + 00)
%define tPartitionInfo.PCISubclass				(esi + 04)
%define tPartitionInfo.PCIBus					(esi + 08)
%define tPartitionInfo.PCIDevice				(esi + 12)
%define tPartitionInfo.PCIFunction				(esi + 16)
%define tPartitionInfo.driveListNumber			(esi + 20)
%define tPartitionInfo.startingLBA				(esi + 24)
%define tPartitionInfo.sectorCount				(esi + 28)
%define tPartitionInfo.fileSystem				(esi + 32)
%define tPartitionInfo.attributes				(esi + 36)
%define tPartitionInfo.ATABasePort				(esi + 40)
%define tPartitionInfo.ATAControlPort			(esi + 44)
%define tPartitionInfo.ATADeviceNumber			(esi + 48)
%define tPartitionInfo.reserved1				(esi + 52)
%define tPartitionInfo.reserved2				(esi + 56)
%define tPartitionInfo.reserved3				(esi + 60)
%define tPartitionInfo.reserved4				(esi + 64)
%define tPartitionInfo.reserved5				(esi + 68)
%define tPartitionInfo.reserved6				(esi + 72)
%define tPartitionInfo.reserved7				(esi + 76)
; the following elements are reserved for use by the FS driver for this partition
%define tPartitionInfo.FSReserved00				(esi + 80)
%define tPartitionInfo.FSReserved01				(esi + 84)
%define tPartitionInfo.FSReserved02				(esi + 88)
%define tPartitionInfo.FSReserved03				(esi + 92)
%define tPartitionInfo.FSReserved04				(esi + 96)
%define tPartitionInfo.FSReserved05				(esi + 100)
%define tPartitionInfo.FSReserved06				(esi + 104)
%define tPartitionInfo.FSReserved07				(esi + 108)
%define tPartitionInfo.FSReserved08				(esi + 112)
%define tPartitionInfo.FSReserved09				(esi + 116)
%define tPartitionInfo.FSReserved10				(esi + 120)
%define tPartitionInfo.FSReserved11				(esi + 124)

; partition data as presented on disk
%define tPartitionLayout.bootable				(esi + 00)
%define tPartitionLayout.startingCHS			(esi + 01)
%define tPartitionLayout.systemID				(esi + 04)
%define tPartitionLayout.endingCHS				(esi + 05)
%define tPartitionLayout.startingLBA			(esi + 08)
%define tPartitionLayout.sectorCount			(esi + 12)





; global konstant defines

; error codes
%define kErrNone								0x0000

; function parameter errors
%define kErrInvalidParameter					0xF000
%define kErrValueTooLow							0xF001
%define kErrValueTooHigh						0xF002

; filesystem errors
%define kErrDriveLetterInvalid					0xFB00
%define kErrPathInvalid							0xFB01
%define kErrPathInvalidCharacter				0xFB02
%define kErrItemNotFound						0xFB03
%define kErrClusterChainEndUnexpected			0xFB04

; partition errors
%define kErrInvalidPartitionNumber				0xFC00
%define kErrPartitionFull						0xFC01

; driver handler errors
%define kErrHandlerNotPresent					0xFD00

; memory errors
%define kErrOutOfMemory							0xFE00

; PS/2 controller errors
%define kErrPS2AckFail							0xFF00
%define kErrPS2ControllerReadTimeout			0xFF01
%define kErrPS2ControllerWriteTimeout			0xFF02



; block and character driver commands
%define kDriverInit								0x00
%define kDriverMediaCheck						0x01
%define kDriverBuildBPB							0x02
%define kDriverIOCTLRead						0x03
%define kDriverRead								0x04
%define kDriverNondestructiveRead				0x05
%define kDriverInputStatus						0x06
%define kDriverFlushInputBuffers				0x07
%define kDriverWrite							0x08
%define kDriverWriteVerify						0x09
%define kDriverOutputStatus						0x0A
%define kDriverFlushOutputBuffers				0x0B
%define kDriverIOCTLWrite						0x0C
%define kDriverOpen								0x0D
%define kDriverClose							0x0E
%define kDriverRemovableMedia					0x0F
%define kDriverOutputUntilBusy					0x10

; file system driver commands
%define kDriverFileDelete						0xF0
%define kDriverFileInfoAccessedGet				0xF1
%define kDriverFileInfoCreatedGet				0xF2
%define kDriverFileInfoModifiedGet				0xF3
%define kDriverFileInfoSizeGet					0xF4
%define kDriverFileLoad							0xF5
%define kDriverFileStore						0xF6





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

; MS-DOS Driver Command Codes
; 00	Init					MS-DOS makes the driver initialization call (command code 0) only to install the device driver after the system is booted. It is never called again. Accordingly, it is a common practice among writers of device drivers to place it physically at the end of the device driver code, where it can be abandoned. Its function is to perform any hardware initialization needed.
; 01	Media Check				Useful for block devices only. (Character devices should simply return DONE. I will not repeat this warning for other command codes that you use with only one type of device.) MS-DOS makes this call to determine whether or not the media has been changed.
; 02	Build BPB				Useful only to block device drivers. MS-DOS makes this call when the media has been legally changed. (Either the media check call has returned "media changed" or it returned "don't know," and there are no buffers to be written to the media.) The routine returns a BIOS parameter block describing the media. Under MS-DOS version 3 and up, it also reads the volume label and saves it.
; 03	IOCTL Read				MS-DOS performs this only if the I/O-control bit is set in the device attributes word. It allows application programs to access control information from the driver (what baud rate, etc.).
; 04	Read					Transfers data from the device to a memory buffer. If an error occurs, the handler must return an error code and report the number of bytes or blocks successfully transferred.
; 05	Non-destructive read	Valid only for character devices. Its purpose is to allow MS-DOS to look ahead one character without removing the character from the input buffer.
; 06	Input status			Valid only for character devices. Its purpose is to tell MS-DOS whether or not there are characters in the input buffer. It does so by setting the busy bit in the returned status to indicate if the buffer is empty. An unbuffered character device should return a clear busy bit; otherwise, MS-DOS will hang up, waiting for data in a nonexistent buffer! This call uses no additional fields.
; 07	Flush input buffers		Valid only for character devices. If the device supports buffered input, it should discard the characters in the buffer. This call uses no additional fields.
; 08	Write					Transfers data from the specified memory buffer to the device. If an error occurs, it must return an error code and report the number of bytes or blocks successfully transferred.
; 09	Write with verify		Identical to the write call, except that a read-after-write verify is performed if possible.
; 10	Output status			Used only on character devices. Its purpose is to inform MS-DOS whether the next write request will have to wait for the previous request to complete by returning the busy bit set. This call uses no additional fields.
; 11	Flush output buffers	Used only on character devices. If the output is buffered, the driver should discard the data in the buffer. This call uses no additional fields.
; 12	IOCTL Write				MS-DOS performs this only if the I/O-control bit is set in the device attributes word. It allows application programs to pass control information to the driver (what baud rate, etc.).
; 13	Open					Available only for MS-DOS version 3 and up. MS-DOS makes this call only if the open/close/removable media bit is set in the device attributes word. This call can be used to tell a character device to send an initializing control string, as to a printer. It can be used on block devices to control local buffering schemes. Note that the predefined handles for the CON, AUX, and PRN devices are always open. This call uses no additional fields.
; 14	Close					Available only for MS-DOS version 3 and up. MS-DOS makes this call only if the open/close/removable media bit is set in the device attributes word. This call can be used to tell a character device to send a terminating control string, as to a printer. It can be used on block devices to control local buffering schemes. Note that the predefined handles for the CON, AUX, and PRN devices are never closed. This call uses no additional fields.
; 15	Removable media			Available only for MS-DOS version 3 and up, and only for block devices where the open/close/removable media bit is set in the device attributes word. If the media is removable, the function returns the busy bit set. This call uses no additional fields.
; 16	Output until busy		Available only for MS-DOS version 3 and up, and is called only if the output-until-busy bit is set in the device attributes word. It only pertains to character devices. This call is an optimization designed for use with print spoolers. It causes data to be written from the specified buffer to the device until the device is busy. It is not an error, therefore, for the driver to report back fewer bytes written than were specified.

; VirtualBox PCI Device Summary
; Bus	Device	Function	Vendor	Device	Class	Subclass	ProgIf	Revision	Description
; 000	00		0			8086	1237	06		00			00		02			Bridge Device
; 000	01		0			8086	7000	06		01			00		00			Bridge Device
; 000	01		1			8086	7111	01		01			8A		01			Mass Storage Controller
; 000	02		0			80EE	BEEF	03		00			00		00			Display Controller
; 000	03		0			1022	2000	02		00			00		40			Network Controller
; 000	04		0			80EE	CAFE	08		80			00		00			Generic System Peripheral
; 000	05		0			8086	2415	04		01			00		01			Multimedia Controller
; 000	06		0			106B	003F	0C		03			10		00			USB Controller
; 000	07		0			8086	7113	06		80			00		08			Bridge Device

