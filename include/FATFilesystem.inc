; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; FAT Filesystem.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; function definitions
extern FAT16CalcLBAClusterToSector
extern FAT16CalcSpaceNeeded
extern FAT16CalcTableElementFromCluster
extern FAT16ChainDelete
extern FAT16ChainGrow
extern FAT16ChainLength
extern FAT16ChainRead
extern FAT16ChainResize
extern FAT16ChainShrink
extern FAT16ChainWrite
extern FAT16ClusterFreeFirstGet
extern FAT16ClusterFreeTotalGet
extern FAT16ClusterNextGet
extern FAT16ClusterNextSet
extern FAT16EntryBuild
extern FAT16FATBackup
extern FAT16FileWrite
extern FAT16ItemCount
extern FAT16ItemDelete
extern FAT16ItemExists
extern FAT16ItemInfoAccessedGet
extern FAT16ItemInfoCreatedGet
extern FAT16ItemInfoModifiedGet
extern FAT16ItemInfoSizeGet
extern FAT16ItemLoad
extern FAT16ItemMatch
extern FAT16ItemNew
extern FAT16ItemStore
extern FAT16PartitionCacheData
extern FAT16PartitionInfo
extern FAT16PathCanonicalize
extern FAT16ServiceHandler
extern FAT32ServiceHandler
extern FATDecodeDate
extern FATDecodeTime
extern FATEncodeDate
extern FATEncodeFilename
extern FATEncodeTime
