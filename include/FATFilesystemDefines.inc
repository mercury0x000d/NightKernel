; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; FAT Filesystem.def is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; FAT directory entry format
struc tFATDirEntry
	.name										resb 8
	.extension									resb 3
	.attributes									resb 1
	.VFATCaseInfo								resb 1
	.createTimeSeconds							resb 1
	.createTime									resw 1
	.createDate									resw 1
	.lastAccessDate								resw 1
	.extendedAttributes							resw 1
	.lastModifiedTime							resw 1
	.lastModifiedDate							resw 1
	.startingCluster							resw 1
	.size										resd 1
endstruc

; tFAT16BPB, for the BIOS Parameter Block on a FAT16 formatted disk
struc tFAT16BPB
	.jump										resb 3
	.OEM										resb 8
	.bytesPerSector								resw 1
	.sectorsPerCluster							resb 1
	.reservedSectors							resw 1
	.FATCount									resb 1
	.rootDirectoryEntries						resw 1
	.totalSectors								resw 1
	.mediaDescriptor							resb 1
	.sectorsPerFAT								resw 1
	.sectorsPerTrack							resw 1
	.headCount									resw 1
	.hiddenSectors								resd 1
	.totalSectorCountLarge						resd 1
	.driveNumber								resb 1
	.reserved									resb 1
	.signature									resb 1
	.volumeSerial								resd 1
	.volumeLabel								resb 11
	.FSIdentifier								resb 8
	.bootCode									resb 448
	.partitionSignature							resw 1
endstruc

; FAT attribute codes
%define kFATAttributeReadOnly					0x01
%define kFATAttributeHidden						0x02
%define kFATAttributeSystem						0x04
%define kFATAttributeVolumeID					0x08
%define kFATAttributeDirectory					0x10
%define kFATAttributeArchive					0x20

; (re)defines for the FS handler space of the tPartitionInfo entry - a cache of sorts
%define tPartitionInfo.FSFlags					tPartitionInfo.FSReserved00
%define tPartitionInfo.sectorsPerCluster		tPartitionInfo.FSReserved01
%define tPartitionInfo.rootDirEntries			tPartitionInfo.FSReserved02
%define tPartitionInfo.rootDirSectorCount		tPartitionInfo.FSReserved03
%define tPartitionInfo.rootDirSize				tPartitionInfo.FSReserved04
%define tPartitionInfo.sectorsPerFAT			tPartitionInfo.FSReserved05
%define tPartitionInfo.bytesPerCluster			tPartitionInfo.FSReserved06
%define tPartitionInfo.FAT1						tPartitionInfo.FSReserved07
%define tPartitionInfo.FAT2						tPartitionInfo.FSReserved08
%define tPartitionInfo.rootDir					tPartitionInfo.FSReserved09
%define tPartitionInfo.dataArea					tPartitionInfo.FSReserved10
%define tPartitionInfo.clusterCount				tPartitionInfo.FSReserved11





; declare function as global
global FAT16CalcLBAClusterToSector
global FAT16CalcSpaceNeeded
global FAT16CalcTableElementFromCluster
global FAT16ChainDelete
global FAT16ChainGrow
global FAT16ChainLength
global FAT16ChainRead
global FAT16ChainResize
global FAT16ChainShrink
global FAT16ChainWrite
global FAT16ClusterFreeFirstGet
global FAT16ClusterFreeTotalGet
global FAT16ClusterNextGet
global FAT16ClusterNextSet
global FAT16EntryBuild
global FAT16FATBackup
global FAT16FileWrite
global FAT16ItemCount
global FAT16ItemDelete
global FAT16ItemExists
global FAT16ItemInfoAccessedGet
global FAT16ItemInfoCreatedGet
global FAT16ItemInfoModifiedGet
global FAT16ItemInfoSizeGet
global FAT16ItemLoad
global FAT16ItemMatch
global FAT16ItemNew
global FAT16ItemStore
global FAT16PartitionCacheData
global FAT16PartitionInfo
global FAT16PathCanonicalize
global FAT16ServiceHandler
global FAT32ServiceHandler
global FATDecodeDate
global FATDecodeTime
global FATEncodeDate
global FATEncodeFilename
global FATEncodeTime
