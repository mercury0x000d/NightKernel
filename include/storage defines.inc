; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; storage defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; partition data as presented on disk
struc tPartitionLayout
	.bootable									resb 1
	.startingCHS								resb 3
	.systemID									resb 1
	.endingCHS									resb 3
	.startingLBA								resd 1
	.sectorCount								resd 1
endstruc

; boot sector offsets
%define tMBR.Bootstrap							0x0000
%define tMBR.OUID								0x01B4
%define tMBR.PartitionOffsetA					0x01BE
%define tMBR.PartitionOffsetB					0x01CE
%define tMBR.PartitionOffsetC					0x01DE
%define tMBR.PartitionOffsetD					0x01EE
%define tMBR.Signature							0x01FE





; declare functions as global
global SMDiskRead
global SMItemCount
global SMItemDelete
global SMItemExists
global SMItemInfoAccessedGet
global SMItemInfoCreatedGet
global SMItemInfoModifiedGet
global SMItemInfoSizeGet
global SMItemLoad
global SMItemNew
global SMItemStore
global SMPartitionEnumerate
global SMPartitionMap
global SMPartitionRead
global SMPartitionWrite
global SMPartitionInfo
global SMPathParentGet
global SMPathPartitionGet
global SMPathPartitionStripDrive
global SMPathValidate
