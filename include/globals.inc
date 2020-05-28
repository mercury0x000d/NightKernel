; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
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
%include "include/globalsDefines.inc"

extern tSystem.APMFeatures
extern tSystem.APMVersionMajor
extern tSystem.APMVersionMinor
extern tSystem.configBits
extern tSystem.configBitsHint$
extern tSystem.copyright$
extern tSystem.CPUFeatures
extern tSystem.CPUIDBrand$
extern tSystem.CPUIDLargestBasicQuery
extern tSystem.CPUIDLargestExtendedQuery
extern tSystem.CPUIDVendor$
extern tSystem.currentTask
extern tSystem.currentTaskSlotAddress
extern tSystem.listPtrDriveLetters
extern tSystem.listPtrDrives
extern tSystem.listPtrFSHandlers
extern tSystem.listPtrPartitions
extern tSystem.listPtrPCIHandlers
extern tSystem.listPtrPS2Handlers
extern tSystem.listPtrTasks
extern tSystem.memoryBIOSMapEntryCount
extern tSystem.memoryBIOSMapKiBInstalled
extern tSystem.memoryBIOSMapKiBUsable
extern tSystem.memoryBIOSMapPtr
extern tSystem.memoryBIOSMapSize
extern tSystem.memoryBitfieldAllocatedPtr
extern tSystem.memoryBitfieldReservedPtr
extern tSystem.memoryBitfieldSize
extern tSystem.memoryBitsInitial
extern tSystem.memoryManagementSpace
extern tSystem.mouseButtonCount
extern tSystem.mouseButtons
extern tSystem.mousePacketByte0
extern tSystem.mousePacketByte1
extern tSystem.mousePacketByte2
extern tSystem.mousePacketByte3
extern tSystem.mousePacketByteCount
extern tSystem.mousePacketByteSize
extern tSystem.mouseWheelPresent
extern tSystem.mouseX
extern tSystem.mouseXLimit
extern tSystem.mouseY
extern tSystem.mouseYLimit
extern tSystem.mouseZ
extern tSystem.multicoreAvailable
extern tSystem.PCICapabilities
extern tSystem.PCIDeviceCount
extern tSystem.PCIVersion
extern tSystem.PS2Config
extern tSystem.PS2Port1DeviceID
extern tSystem.PS2Port2DeviceID
extern tSystem.RTCDay
extern tSystem.RTCHours
extern tSystem.RTCMinutes
extern tSystem.RTCMonth
extern tSystem.RTCSeconds
extern tSystem.RTCStatusRegisterB
extern tSystem.RTCUpdateHandlerAddress
extern tSystem.RTCYear
extern tSystem.taskingEnable
extern tSystem.taskKernelStackSize
extern tSystem.taskStackSize
extern tSystem.ticksSinceBoot
extern tSystem.versionBuild
extern tSystem.versionMajor
extern tSystem.versionMinor
