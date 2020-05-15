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
extern tSystem.CPUFeatures
extern tSystem.CPUIDLargestBasicQuery
extern tSystem.CPUIDLargestExtendedQuery
extern tSystem.APMVersionMajor
extern tSystem.APMVersionMinor
extern tSystem.APMFeatures
extern tSystem.mouseButtonCount
extern tSystem.mouseButtons
extern tSystem.mousePacketByte0
extern tSystem.mousePacketByte1
extern tSystem.mousePacketByte2
extern tSystem.mousePacketByte3
extern tSystem.mousePacketByteSize
extern tSystem.mousePacketByteCount
extern tSystem.mouseWheelPresent
extern tSystem.mouseX
extern tSystem.mouseXLimit
extern tSystem.mouseY
extern tSystem.mouseYLimit
extern tSystem.mouseZ
extern tSystem.memoryBIOSMapShadowPtr
extern tSystem.memoryBIOSMapShadowEntryCount
extern tSystem.memoryBIOSMapShadowSize
extern tSystem.memoryBitfieldPtrPagesAllocated
extern tSystem.memoryBitfieldPtrPagesReserved
extern tSystem.memoryBitfieldSize
extern tSystem.memoryManagementSpace
extern tSystem.memoryKiBInstalled
extern tSystem.memoryKiBUsable
extern tSystem.listPtrDrives
extern tSystem.listPtrDriveLetters
extern tSystem.listPtrFSHandlers
extern tSystem.listPtrPartitions
extern tSystem.listPtrPCIHandlers
extern tSystem.listPtrTasks
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
extern tSystem.RTCHours
extern tSystem.RTCMinutes
extern tSystem.RTCSeconds
extern tSystem.RTCYear
extern tSystem.RTCMonth
extern tSystem.RTCDay
