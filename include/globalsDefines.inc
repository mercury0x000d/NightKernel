; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; globals defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; global konstant defines

; the BUILD define is used by Xenops, the version-updating tool with the most awesome name ever :D
%define BUILD 4511

; for configbits settings - great idea, Antony!
%define kCBDebugMode							0
%define kCBVerbose								1
%define kCBLines50								2
%define kCBVMEnable								3
%define kCBIntHalt								4

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
%define kDriverItemDelete						0xF0
%define kDriverItemInfoAccessedGet				0xF1
%define kDriverItemInfoCreatedGet				0xF2
%define kDriverItemInfoModifiedGet				0xF3
%define kDriverItemInfoSizeGet					0xF4
%define kDriverItemLoad							0xF5
%define kDriverItemNew							0xF6
%define kDriverItemStore						0xF7
%define kDriverPartitionInfo					0xF8
%define kDriverItemCount						0xF9
%define kDriverItemExists						0xFA





; global sTrucTures go here...
; tDriveInfo, for the drives list (120 bytes)
struc tDriveInfo
	.model										resb 64
	.serial										resb 32
	.PCIClass									resd 1
	.PCISubclass								resd 1
	.PCIBus										resd 1
	.PCIDevice									resd 1
	.PCIFunction								resd 1
	.cacheAddress								resd 1
	.deviceFlags								resd 1
	.ATABasePort								resd 1
	.ATAControlPort								resd 1
	.ATADeviceNumber							resd 1
	.reserved00									resd 1
	.reserved01									resd 1
	.reserved02									resd 1
	.reserved03									resd 1
	.reserved04									resd 1
	.reserved05									resd 1
	.reserved06									resd 1
	.reserved07									resd 1
	.reserved08									resd 1
	.reserved09									resd 1
	.reserved10									resd 1
	.reserved11									resd 1
	.reserved12									resd 1
	.reserved13									resd 1
endstruc

; tPartitionInfo, for the partitions list (128 bytes)
struc tPartitionInfo
	.PCIClass									resd 1
	.PCISubclass								resd 1
	.PCIBus										resd 1
	.PCIDevice									resd 1
	.PCIFunction								resd 1
	.driveListNumber							resd 1
	.startingLBA								resd 1
	.sectorCount								resd 1
	.fileSystem									resd 1
	.attributes									resd 1
	.ATABasePort								resd 1
	.ATAControlPort								resd 1
	.ATADeviceNumber							resd 1
	.partitionNumber							resd 1
	.reserved1									resd 1
	.reserved2									resd 1
	.reserved3									resd 1
	.reserved4									resd 1
	.reserved5									resd 1
	.reserved6									resd 1

	; the following elements are reserved for use by the FS driver for this partition
	.FSReserved00								resd 1
	.FSReserved01								resd 1
	.FSReserved02								resd 1
	.FSReserved03								resd 1
	.FSReserved04								resd 1
	.FSReserved05								resd 1
	.FSReserved06								resd 1
	.FSReserved07								resd 1
	.FSReserved08								resd 1
	.FSReserved09								resd 1
	.FSReserved10								resd 1
	.FSReserved11								resd 1
endstruc





; declare as global
global tSystem.APMFeatures
global tSystem.APMVersionMajor
global tSystem.APMVersionMinor
global tSystem.configBits
global tSystem.configBitsHint$
global tSystem.copyright$
global tSystem.CPUFeatures
global tSystem.CPUIDBrand$
global tSystem.CPUIDLargestBasicQuery
global tSystem.CPUIDLargestExtendedQuery
global tSystem.CPUIDVendor$
global tSystem.currentTask
global tSystem.currentTaskSlotAddress
global tSystem.listPtrDriveLetters
global tSystem.listPtrDrives
global tSystem.listPtrFSHandlers
global tSystem.listPtrPartitions
global tSystem.listPtrPCIHandlers
global tSystem.listPtrPS2Handlers
global tSystem.listPtrTasks
global tSystem.memoryBIOSMapEntryCount
global tSystem.memoryBIOSMapKiBInstalled
global tSystem.memoryBIOSMapKiBUsable
global tSystem.memoryBIOSMapPtr
global tSystem.memoryBIOSMapSize
global tSystem.memoryBitfieldAllocatedPtr
global tSystem.memoryBitfieldReservedPtr
global tSystem.memoryBitfieldSize
global tSystem.memoryBitsInitial
global tSystem.memoryManagementSpace
global tSystem.mouseButtonCount
global tSystem.mouseButtons
global tSystem.mousePacketByte0
global tSystem.mousePacketByte1
global tSystem.mousePacketByte2
global tSystem.mousePacketByte3
global tSystem.mousePacketByteCount
global tSystem.mousePacketByteSize
global tSystem.mouseWheelPresent
global tSystem.mouseX
global tSystem.mouseXLimit
global tSystem.mouseY
global tSystem.mouseYLimit
global tSystem.mouseZ
global tSystem.multicoreAvailable
global tSystem.PCICapabilities
global tSystem.PCIDeviceCount
global tSystem.PCIVersion
global tSystem.PS2Config
global tSystem.PS2Port1DeviceID
global tSystem.PS2Port2DeviceID
global tSystem.RTCDay
global tSystem.RTCHours
global tSystem.RTCMinutes
global tSystem.RTCMonth
global tSystem.RTCSeconds
global tSystem.RTCStatusRegisterB
global tSystem.RTCUpdateHandlerAddress
global tSystem.RTCYear
global tSystem.taskingEnable
global tSystem.taskKernelStackSize
global tSystem.taskStackSize
global tSystem.ticksSinceBoot
global tSystem.versionBuild
global tSystem.versionMajor
global tSystem.versionMinor
