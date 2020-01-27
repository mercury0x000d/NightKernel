; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; globals.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; variable definitions

; global konstant defines

; the BUILD define is used by Xenops, the version-updating tool with the most awesome name ever :D
%define BUILD 2723

; for configbits settings - great idea, Antony!
%define kCBDebugMode							0
%define kCBVerbose								1
%define kCBLines50								2
%define kCBVMEnable								3

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

%define tDriveInfo_size                         192
%define tPartitionInfo_size                     80

extern tDriveInfo.model					
extern tDriveInfo.serial										
extern tDriveInfo.PCIClass									
extern tDriveInfo.PCISubclass								
extern tDriveInfo.PCIBus										
extern tDriveInfo.PCIDevice									
extern tDriveInfo.PCIFunction								
extern tDriveInfo.cacheAddress								
extern tDriveInfo.deviceFlags								
extern tDriveInfo.ATABasePort								
extern tDriveInfo.ATAControlPort								
extern tDriveInfo.ATADeviceNumber							
extern tDriveInfo.reserved00									
extern tDriveInfo.reserved01									
extern tDriveInfo.reserved02									
extern tDriveInfo.reserved03									
extern tDriveInfo.reserved04									
extern tDriveInfo.reserved05									
extern tDriveInfo.reserved06									
extern tDriveInfo.reserved07									
extern tDriveInfo.reserved08									
extern tDriveInfo.reserved09									
extern tDriveInfo.reserved10									
extern tDriveInfo.reserved11									
extern tDriveInfo.reserved12									
extern tDriveInfo.reserved13									

extern tPartitionInfo.PCIClass
extern tPartitionInfo.PCISubclass
extern tPartitionInfo.PCIBus
extern tPartitionInfo.PCIDevice
extern tPartitionInfo.PCIFunction
extern tPartitionInfo.driveListNumber
extern tPartitionInfo.startingLBA
extern tPartitionInfo.sectorCount
extern tPartitionInfo.fileSystem
extern tPartitionInfo.attributes
extern tPartitionInfo.ATABasePort
extern tPartitionInfo.ATAControlPort
extern tPartitionInfo.ATADeviceNumber
extern tPartitionInfo.partitionNumber
extern tPartitionInfo.reserved1
extern tPartitionInfo.reserved2
extern tPartitionInfo.reserved3
extern tPartitionInfo.reserved4
extern tPartitionInfo.reserved5
extern tPartitionInfo.reserved6
extern tPartitionInfo.FSReserved00
extern tPartitionInfo.FSReserved01
extern tPartitionInfo.FSReserved02
extern tPartitionInfo.FSReserved03
extern tPartitionInfo.FSReserved04
extern tPartitionInfo.FSReserved05
extern tPartitionInfo.FSReserved06
extern tPartitionInfo.FSReserved07
extern tPartitionInfo.FSReserved08
extern tPartitionInfo.FSReserved09
extern tPartitionInfo.FSReserved10
extern tPartitionInfo.FSReserved11

extern tSystem.configBitsHint$
extern tSystem.configBits
extern tSystem.copyright$
extern tSystem.versionMajor
extern tSystem.versionMinor
extern tSystem.versionBuild
extern tSystem.ticksSinceBoot
extern tSystem.currentTask
extern tSystem.currentTaskSlotAddress
extern tSystem.taskingEnable
extern tSystem.taskStackSize
extern tSystem.taskKernelStackSize
extern tSystem.multicoreAvailable
extern tSystem.CPUIDVendor$
extern tSystem.CPUIDBrand$
extern tSystem.CPUIDLargestBasicQuery
extern tSystem.CPUIDLargestExtendedQuery
extern tSystem.APMVersionMajor
extern tSystem.APMVersionMinor
extern tSystem.APMFeatures
extern tSystem.mouseButtonCount
extern tSystem.mouseButtons
extern tSystem.mousePacketByteSize
extern tSystem.mousePacketByteCount
extern tSystem.mousePacketByte0
extern tSystem.mousePacketByte1
extern tSystem.mousePacketByte2
extern tSystem.mousePacketByte3
extern tSystem.mouseWheelPresent
extern tSystem.mouseX
extern tSystem.mouseXLimit
extern tSystem.mouseY
extern tSystem.mouseYLimit
extern tSystem.mouseZ
extern tSystem.memoryInstalledBytes
extern tSystem.listDrives
extern tSystem.listDriveLetters
extern tSystem.listFSHandlers
extern tSystem.listMemory
extern tSystem.listPartitions
extern tSystem.listPCIHandlers
extern tSystem.listTasks
extern tSystem.memoryInitialAvailableBytes
extern tSystem.memoryFreeBytes
extern tSystem.memoryListReservedSpace
extern tSystem.PCIDeviceCount
extern tSystem.PCIVersion
extern tSystem.PCICapabilities
extern tSystem.PS2ControllerConfig
extern tSystem.PS2ControllerPort1Status
extern tSystem.PS2ControllerPort2Status
extern tSystem.PS2ControllerDeviceID1
extern tSystem.PS2ControllerDeviceID2
extern tSystem.RTCUpdateHandlerAddress
extern tSystem.RTCStatusRegisterB
extern tSystem.hours
extern tSystem.minutes
extern tSystem.seconds
extern tSystem.year
extern tSystem.month
extern tSystem.day
