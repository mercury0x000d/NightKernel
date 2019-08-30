; 2048 bytes per cluster, 20348 clusters total, 16073 clusters free
; 41672704 bytes total, 32917504 bytes free

; name				  size		date		time
; logging.bas		  1572		12/13/90	00:00
; john.txt			102388		06/24/19	07:02
; lincoln.txt		  1511		06/24/19	08:56
; who.txt			   117		07/09/19	12:08

;	contents				LBA address in partition		length in sectors		address
;	reserved sectors		0								1						207E00 - 207EFF
;	FAT 1					1 - 28							28						208000 - 20CFFF
;	FAT 2					29 - 50							28						20D000 - 211FFF
;	rootDir					51 - 70							20						212000 - 215FFF
;	dataArea				71 - ...						...						216000 - ...		(cluster 2)

; http://www.maverick-os.dk/FileSystemFormats/FAT16_FileSystem.html





; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; FAT Filesystem.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 32-bit function listing:
; FAT16CalcClustersNeeded				Determines the number of clusters needed to store a file of the specified size
; FAT16CalcLBAClusterToSector			Returns the LBA address of the sector pointed to by the cluster number specified
; FAT16CalcTableElementFromCluster		Translates the specified FAT table entry into offsets from the start of the FAT table
; FAT16ChainDelete						Deletes the cluster chain specified
; FAT16ChainGrow						Extends the cluster chain specified to the length specified
; FAT16ChainLength						Returns the length in clusters of the cluster chain specified
; FAT16ChainRead						Reads the cluster chain specified into memory at the address specified
; FAT16ChainResize						Resizes the cluster chain specified to the length specified
; FAT16ChainShrink						Shortens the cluster chain specified to the length specified
; FAT16ChainWrite						Writes the cluster chain specified to disk
; FAT16ClusterFreeFirstGet				Returns the first free cluster in the FAT
; FAT16ClusterFreeTotalGet				Returns total number of free clusters for the partition specified
; FAT16ClusterNextGet					Determines the next cluster in the chain
; FAT16ClusterNextSet					Sets the next cluster in the chain from the cluster specified
; FAT16DirEntryMatchName				Returns the address of a match for the item specified in the buffer specified
; FAT16FATBackup						Copies the working FAT (the first FAT) to any remaining spots in the FAT area
; FAT16FileCreate						Creates a new file at the path specified
; FAT16FileDelete						Deletes the file specified
; FAT16FileInfoAccessedGet				Returns the date and time of last access for the specified file
; FAT16FileInfoCreatedGet				Returns the date and time of creation for the specified file
; FAT16FileInfoModifiedGet				Returns the date and time of last modification for the specified file
; FAT16FileInfoSizeGet					Gets the size of the file specified
; FAT16FileInfoSizeSet					Sets the size of the file specified
; FAT16FileLoad							Loads the file specified at the address specified using FAT16 standards
; FAT16FileStore						Stores the range of memory specified as a file at the FAT16 path specified
; FAT16FileWrite						Writes data from memory to the file structure on disk
; FAT16ItemExists						Tests if the item specified already exists
; FAT16PartitionCacheData				Caches FAT16-specific data from sector 0 of the partition to the FS reserved section of this partiton's entry in the partitions list
; FAT16PathCanonicalize					Returns the proper form of the path specified according to FAT16 standards
; FAT16PathToDirEntry					Returns a buffer containing the directory entry containing the item specified by the path given
; FAT16ServiceHandler					The FAT16 service routine called by external applications

; FAT32ServiceHandler					The FAT32 service routine called by external applications

; FATDecodeDate							Extracts the month, day, and year from the numeric representation as found in a file's directory entry
; FATDecodeTime							Extracts the hours, minutes, and seconds from the numeric representation as found in a file's directory entry
; FATEncodeDate							Encodes the month, day, and year specified into the numeric representation found in a file's directory entry
; FATEncodeFilename						Formats the specified filename as it would appear in a FAT directory table
; FATEncodeTime							Encodes the hours, minutes, and seconds specified into the numeric representation found in a file's directory entry





; FAT directory entry format
%define tFATDirEntry.name						(esi + 00)		; 8 bytes
%define tFATDirEntry.extension					(esi + 08)		; 3 bytes
%define tFATDirEntry.attributes					(esi + 11)		; byte
%define tFATDirEntry.VFATCaseInfo				(esi + 12)		; byte
%define tFATDirEntry.createTimeSeconds			(esi + 13)		; byte
%define tFATDirEntry.createTime					(esi + 14)		; word
%define tFATDirEntry.createDate					(esi + 16)		; word
%define tFATDirEntry.lastAccessDate				(esi + 18)		; word
%define tFATDirEntry.extendedAttributes			(esi + 20)		; word
%define tFATDirEntry.lastModifiedTime			(esi + 22)		; word
%define tFATDirEntry.lastModifiedDate			(esi + 24)		; word
%define tFATDirEntry.startingCluster			(esi + 26)		; word
%define tFATDirEntry.size						(esi + 28)		; dword

; FAT attribute codes
%define kFATAttributeReadOnly					0x01
%define kFATAttributeHidden						0x02
%define kFATAttributeSystem						0x04
%define kFATAttributeVolumeID					0x08
%define kFATAttributeDirectory					0x10
%define kFATAttributeArchive					0x20

; tFAT16BPB, for the BIOS Parameter Block on a FAT16 formatted disk
%define tFAT16BPB.jump							(esi + 000)		; 3 bytes
%define tFAT16BPB.OEM							3				; 8 bytes
%define tFAT16BPB.bytesPerSector				(esi + 011)		; word
%define tFAT16BPB.sectorsPerCluster				(esi + 013)		; byte
%define tFAT16BPB.reservedSectors				(esi + 014)		; word
%define tFAT16BPB.FATCount						(esi + 016)		; byte
%define tFAT16BPB.rootDirectoryEntries			(esi + 017)		; word
%define tFAT16BPB.totalSectors					(esi + 019)		; word
%define tFAT16BPB.mediaDescriptor				(esi + 021)		; byte
%define tFAT16BPB.sectorsPerFAT					(esi + 022)		; word
%define tFAT16BPB.sectorsPerTrack				(esi + 024)		; word
%define tFAT16BPB.headCount						(esi + 026)		; word
%define tFAT16BPB.hiddenSectors					(esi + 028)		; dword
%define tFAT16BPB.totalSectorCountLarge			(esi + 032)		; dword
%define tFAT16BPB.driveNumber					(esi + 036)		; byte
%define tFAT16BPB.reserved						(esi + 037)		; byte
%define tFAT16BPB.signature						(esi + 038)		; byte
%define tFAT16BPB.volumeSerial					39				; dword
%define tFAT16BPB.volumeLabel					43				; 11 bytes
%define tFAT16BPB.FSIdentifier					54				; 8 bytes
%define tFAT16BPB.bootCode						62				; 
%define tFAT16BPB.partitionSignature			(esi + 510)		; word

; (re)defines for the FS handler space of the tPartitionInfo entry - a cache of sorts
%define tPartitionInfo.FSFlags					(esi + 80)
%define tPartitionInfo.sectorsPerCluster		(esi + 84)
%define tPartitionInfo.rootDirectoryEntries		(esi + 88)
%define tPartitionInfo.sectorsPerFAT			(esi + 92)
%define tPartitionInfo.bytesPerCluster			(esi + 96)
%define tPartitionInfo.FAT1						(esi + 100)
%define tPartitionInfo.FAT2						(esi + 104)
%define tPartitionInfo.rootDir					(esi + 108)
%define tPartitionInfo.dataArea					(esi + 112)
%define tPartitionInfo.clusterCount				(esi + 116)





bits 32





section .text
FAT16CalcClustersNeeded:
	; Determines the number of clusters needed to store a file of the specified size
	;
	;  input:
	;	Sectors per cluster
	;	File size
	;
	;  output:
	;	EAX - Clusters needed

	push ebp
	mov ebp, esp

	; define input parameters
	%define sectorsPerCluster					dword [ebp + 8]
	%define fileSize							dword [ebp + 12]


	; calculate!
	mov ebx, sectorsPerCluster
	shl ebx, 9
	mov eax, fileSize
	mov edx, 0
	div ebx

	cmp edx, 0
	je .Exit
		inc eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16CalcLBAClusterToSector:
	; Returns the LBA address of the sector pointed to by the cluster number specified
	;
	;  input:
	;	Cluster number
	;	Number of sectors per cluster on the disk
	;	LBA address of the disk's data area
	;
	;  output:
	;	EAX - Sector LBA address

	push ebp
	mov ebp, esp


	; define input parameters
	%define cluster								dword [ebp + 8]
	%define sectorsPerCluster					dword [ebp + 12]
	%define dataArea							dword [ebp + 16]


	; sector = (cluster - 2) * sectorsPerCluster + dataArea
	mov eax, cluster
	sub eax, 2
	mul sectorsPerCluster
	add eax, dataArea


	.Exit:
	mov esp, ebp
	pop ebp
ret 12






section .text
FAT16CalcTableElementFromCluster:
	; Translates the specified FAT table entry into offsets from the start of the FAT table
	;
	;  input:
	;	FAT table entry
	;
	;  output:
	;	EAX - Sector offset from start of FAT
	;	EBX - Byte offset within that sector of the requested entry

	push ebp
	mov ebp, esp

	; define input parameters
	%define element								dword [ebp + 8]


	shl element, 1

	mov eax, element
	shr eax, 9

	mov ebx, element
	and ebx, 0x01FF


	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16ChainDelete:
	; Deletes the cluster chain specified
	;
	;  input:
	;	Partition number
	;	Starting cluster for chain
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp


	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define cluster								dword [ebp + 12]

	; allocate local variables
	sub esp, 28
	%define partitionSlotPtr					dword [ebp - 4]
	%define sectorOffset						dword [ebp - 8]
	%define bytePosition						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]
	%define FATLBA								dword [ebp - 28]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [tPartitionInfo.FAT1]
	mov FATLBA, eax


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov sectorOffset, eax
		mov bytePosition, ebx

		; calculate the sector which needs read
		mov eax, FATLBA
		add eax, sectorOffset
		mov thisSector, eax

		; see if this sector is the same as the one already in the buffer and skip loading if so
		cmp lastSector, eax
		je .LoadSkip
			; if we get here, the sectors are different, so we need to save the current one
			push sectorBufferPtr
			push 1
			push lastSector
			push partitionNumber
			call PartitionWrite

			; update lastSector
			mov eax, thisSector
			mov lastSector, eax

			; read the sector into the buffer
			push sectorBufferPtr
			push 1
			push thisSector
			push partitionNumber
			call PartitionRead
		.LoadSkip:

		; read the number of the next cluster in the chain into bx and clear it
		mov esi, sectorBufferPtr
		add esi, bytePosition
		mov ebx, 0
		mov bx, word [esi]
		mov cluster, ebx
		mov word [esi], 0

		; see if the cluster number indicates we're at the end of the file
		push 0xFFEF
		push 0x0002
		push ebx
		call RangeCheck

		; if the above call returned false, we're at the end of the file
		cmp al, false
		je .LoopDone

	jmp .ClusterLoop

	.LoopDone:
	; write the last sector back
	push sectorBufferPtr
	push 1
	push thisSector
	push partitionNumber
	call PartitionWrite

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose


	.Exit:
	mov esp, ebp
	pop ebp
ret 8






section .text
FAT16ChainGrow:
	; Extends the cluster chain specified to the length specified
	;
	;  input:
	;	Partition number
	;	LBA sector number (relative to this partition) of FAT
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define FATLBA								dword [ebp + 12]
	%define cluster								dword [ebp + 16]
	%define newLength							dword [ebp + 20]

	; allocate local variables
	sub esp, 32
	%define sectorOffset						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define clusterCount						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]
	%define newCluster							dword [ebp - 28]
	%define lastCluster							dword [ebp - 32]


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, save the returned pointer if not
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; zero the vars
	mov clusterCount, 0

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:
		inc clusterCount

		; infinite loops are bad, kids
		cmp clusterCount, 0
		je .Exit

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov sectorOffset, eax
		mov bytePosition, ebx

		; calculate the sector which needs read
		mov eax, FATLBA
		add eax, sectorOffset
		mov thisSector, eax

		; see if this sector is the same as the one already in the buffer and skip loading if so
		cmp lastSector, eax
		je .LoadSkip
			; if we get here, the sectors are different, so we need to load the new one

			; update lastSector
			mov eax, thisSector
			mov lastSector, eax

			; read the sector into the buffer
			push sectorBufferPtr
			push 1
			push thisSector
			push partitionNumber
			call PartitionRead
		.LoadSkip:

		; save the curent value of cluster into lastCluster
		mov eax, cluster
		mov lastCluster, eax

		; read the number of the next cluster in the chain into bx
		mov esi, sectorBufferPtr
		add esi, bytePosition
		mov ebx, 0
		mov bx, word [esi]
		mov cluster, ebx

		; see if the cluster number indicates we're at the end of the file
		push 0xFFEF
		push 0x0002
		push ebx
		call RangeCheck

	; if the above call returned true, we're not yet at the end of the chain
	cmp al, true
	je .ClusterLoop

	.GrowLoop:
		; once we get here, we're at the end of the chain - let's start growing!
		push partitionNumber
		call FAT16ClusterFreeFirstGet
		mov newCluster, eax

		; check for errors
		cmp ebx, kErrNone
		je .NoError
			; do error-y stuff here
		.NoError:

		; update the chain to point to the proper next cluster
		push newCluster
		push lastCluster
		push partitionNumber
		call FAT16ClusterNextSet

		; terminate the chain
		push 0xFFFF
		push newCluster
		push partitionNumber
		call FAT16ClusterNextSet

		; cluster = newCluster
		mov eax, newCluster
		mov lastCluster, eax

		; see if we've processed the proper number of clusters yet
		inc clusterCount
		mov eax, clusterCount
		mov ebx, newLength
		cmp eax, ebx
		je .GrowLoopDone
	jmp .GrowLoop
	
	.GrowLoopDone:
	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; set the return values
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16ChainLength:
	; Returns the length in clusters of the cluster chain specified
	;
	;  input:
	;	Partition number
	;	LBA sector number (relative to this partition) of FAT
	;	Cluster number of start of chain
	;
	;  output:
	;	EAX - Chain length
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define FATLBA								dword [ebp + 12]
	%define cluster								dword [ebp + 16]

	; allocate local variables
	sub esp, 24
	%define sectorOffset						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define clusterCount						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; zero the cluster count
	mov clusterCount, 0

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:
		inc clusterCount

		; infinite loops are bad, kids
		cmp clusterCount, 0
		je .Exit

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov sectorOffset, eax
		mov bytePosition, ebx

		; calculate the sector which needs read
		mov eax, FATLBA
		add eax, sectorOffset
		mov thisSector, eax

		; see if this sector is the same as the one already in the buffer and skip loading if so
		cmp lastSector, eax
		je .LoadSkip
			; if we get here, the sectors are different, so we need to load the new one
			; update lastSector
			mov lastSector, eax

			; read the sector into the buffer
			push sectorBufferPtr
			push 1
			push thisSector
			push partitionNumber
			call PartitionRead
		.LoadSkip:

		; read the number of the next cluster in the chain into bx
		mov esi, sectorBufferPtr
		add esi, bytePosition
		mov ebx, 0
		mov bx, word [esi]
		mov cluster, ebx

		; see if the cluster number indicates we're at the end of the file
		push 0xFFEF
		push 0x0002
		push ebx
		call RangeCheck

		; if the above call returned false, we're at the end of the file
		cmp al, false
		je .Exit

	jmp .ClusterLoop

	.Exit:
	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	mov eax, clusterCount
	mov edx, kErrNone


	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16ChainRead:
	; Reads the cluster chain specified into memory at the address specified
	;
	;  input:
	;	Partition number
	;	Starting cluster for chain
	;	Number of bytes to be loaded
	;	Address at which chain will be loaded
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define cluster								dword [ebp + 12]
	%define size								dword [ebp + 16]
	%define address								dword [ebp + 20]

	; allocate local variables
	sub esp, 32
	%define partitionSlotPtr					dword [ebp - 4]
	%define FAT1								dword [ebp - 8]
	%define sector								dword [ebp - 12]
	%define dataArea							dword [ebp - 16]
	%define sectorsPerCluster					dword [ebp - 20]
	%define bytesPerCluster						dword [ebp - 24]
	%define clusterBufferPtr					dword [ebp - 28]
	%define chunkSize							dword [ebp - 32]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax

	mov eax, [tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	mov eax, [tPartitionInfo.FAT1]
	mov FAT1, eax

	mov eax, [tPartitionInfo.dataArea]
	mov dataArea, eax


	; allocate a cluster buffer
	push bytesPerCluster
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .ClusterBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.ClusterBufferAllocateOK:
	mov clusterBufferPtr, eax

	.ChainReadLoop:

		; see if there's any file left to read
		cmp size, 0
		je .Done

		; get sector LBA from cluster number
		push dataArea
		push sectorsPerCluster
		push cluster
		call FAT16CalcLBAClusterToSector
		mov sector, eax

		; load the cluster into RAM
		push clusterBufferPtr
		push sectorsPerCluster
		push sector
		push partitionNumber
		call PartitionRead

		; see how much data we'll be copying
		; if size/bytesPerCluster is nonzero, we want to copy one cluster
		mov eax, size
		mov edx, 0
		div bytesPerCluster
		mov edx, 0
		cmp eax, 0
		cmovne edx, bytesPerCluster

		; if the above calculation left edx at zero, we copy whatever size is remaining
		cmp edx, 0
		cmove edx, size

		; adjust the size remaining
		sub size, edx

		; save for later the size of the chunk we're copying
		mov chunkSize, edx

		; copy data from the cluster buffer to the buffer address specified
		push edx
		push address
		push clusterBufferPtr
		call MemCopy

		; adjust the pointer into the ouput buffer to prepare it for the next write
		mov eax, chunkSize
		add address, eax

		; get the next cluster in the chain
		push cluster
		push FAT1
		push partitionNumber
		call FAT16ClusterNextGet
		mov cluster, eax

	jmp .ChainReadLoop

	.Done:
	; if we get here, all went as planned!
	push clusterBufferPtr
	call MemDispose

	mov eax, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16ChainResize:
	; Resizes the cluster chain specified to the length specified
	;
	;  input:
	;	Partition number
	;	LBA sector number (relative to this partition) of FAT
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define FATLBA								dword [ebp + 12]
	%define chainStart							dword [ebp + 16]
	%define newLength							dword [ebp + 20]


	; see how long the chain is now
	push chainStart
	push FATLBA
	push partitionNumber
	call FAT16ChainLength

	; if current length > desired length, shrink the chain
	cmp eax, newLength
	jbe .NoShrink
		push newLength
		push chainStart
		push FATLBA
		push partitionNumber
		call FAT16ChainShrink
		jmp .ResizeDone
	.NoShrink:

	; if current length < desired length, grow the chain
	cmp eax, newLength
	jae .NoGrow
		push newLength
		push chainStart
		push FATLBA
		push partitionNumber
		call FAT16ChainGrow
	.NoGrow:


	.ResizeDone:
	mov edx, kErrNone


	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16ChainShrink:
	; Shortens the cluster chain specified to the length specified
	;
	;  input:
	;	Partition number
	;	LBA sector number (relative to this partition) of FAT
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define FATLBA								dword [ebp + 12]
	%define cluster								dword [ebp + 16]
	%define newLength							dword [ebp + 20]

	; allocate local variables
	sub esp, 25
	%define sectorOffset						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define clusterCount						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]
	%define sectorWriteFlag						byte [ebp - 25]


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, save the returned pointer if not
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; zero the vars
	mov clusterCount, 0
	mov sectorWriteFlag, false

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:
		inc clusterCount

		; infinite loops are bad, kids
		cmp clusterCount, 0
		je .Exit

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov sectorOffset, eax
		mov bytePosition, ebx

		; calculate the sector which needs read
		mov eax, FATLBA
		add eax, sectorOffset
		mov thisSector, eax

		; see if this sector is the same as the one already in the buffer and skip loading if so
		cmp lastSector, eax
		je .LoadSkip
			; if we get here, the sectors are different, so we need to load the new one

			; write to disk if anything changed
			call .WriteIfNecessary

			; update lastSector
			mov eax, thisSector
			mov lastSector, eax

			; read the sector into the buffer
			push sectorBufferPtr
			push 1
			push thisSector
			push partitionNumber
			call PartitionRead
		.LoadSkip:

		; read the number of the next cluster in the chain into bx
		mov esi, sectorBufferPtr
		add esi, bytePosition
		mov ebx, 0
		mov bx, word [esi]
		mov cluster, ebx

		; see if the cluster we just read is equal to the new length
		mov eax, clusterCount
		cmp eax, newLength
		jne .NotEqual
			mov word [esi], 0xFFFF
			mov sectorWriteFlag, true
		.NotEqual:

		; see if the cluster we just read is beyond the new length
		cmp eax, newLength
		jna .NotBeyond
			mov word [esi], 0x0000
			mov sectorWriteFlag, true
		.NotBeyond:

		; see if the cluster number indicates we're at the end of the file
		push 0xFFEF
		push 0x0002
		push ebx
		call RangeCheck

		; if the above call returned false, we're at the end of the file
		cmp al, false
		je .Exit

	jmp .ClusterLoop


	.Exit:
	; write to disk if anything changed
	call .WriteIfNecessary

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; set the return values
	mov edx, kErrNone


	mov esp, ebp
	pop ebp
ret 16

.WriteIfNecessary:
	; see if there's anything to write back to disk
	cmp sectorWriteFlag, true
	jne .NoNeedToWrite
		; there's stuff to write, so let's do it
		push sectorBufferPtr
		push 1
		push lastSector
		push partitionNumber
		call PartitionWrite
		mov sectorWriteFlag, false
	.NoNeedToWrite:
ret





section .text
FAT16ChainWrite:
	; Writes the cluster chain specified to disk
	;
	;  input:
	;	Partition number
	;	Starting cluster for chain
	;	Number of bytes to be loaded
	;	Address from which chain will be read
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define cluster								dword [ebp + 12]
	%define size								dword [ebp + 16]
	%define address								dword [ebp + 20]

	; allocate local variables
	sub esp, 32
	%define partitionSlotPtr					dword [ebp - 4]
	%define FAT1								dword [ebp - 8]
	%define sector								dword [ebp - 12]
	%define dataArea							dword [ebp - 16]
	%define sectorsPerCluster					dword [ebp - 20]
	%define bytesPerCluster						dword [ebp - 24]
	%define clusterBufferPtr					dword [ebp - 28]
	%define chunkSize							dword [ebp - 32]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax

	mov eax, [tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	mov eax, [tPartitionInfo.FAT1]
	mov FAT1, eax

	mov eax, [tPartitionInfo.dataArea]
	mov dataArea, eax


	; allocate a cluster buffer
	push bytesPerCluster
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .ClusterBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.ClusterBufferAllocateOK:
	mov clusterBufferPtr, eax


	.ChainWriteLoop:

		; see if there's any file left to write
		cmp size, 0
		je .Done

		; get sector LBA from cluster number
		push dataArea
		push sectorsPerCluster
		push cluster
		call FAT16CalcLBAClusterToSector
		mov sector, eax

		; see how much data we'll be copying
		; if size/bytesPerCluster is nonzero, we want to copy one cluster
		mov eax, size
		mov edx, 0
		div bytesPerCluster
		mov edx, 0
		cmp eax, 0
		cmovne edx, bytesPerCluster

		; if the above calculation left edx at zero, we copy whatever size is remaining
		cmp edx, 0
		cmove edx, size

		; adjust the size remaining
		sub size, edx

		; save for later the size of the chunk we're copying
		mov chunkSize, edx

		; if chunkSize != bytesPerCluster, we need to blank the buffer so that random garbage data doesn't get
		; written in the space between the end of the file and the end of the cluster
		cmp edx, bytesPerCluster
		je .BlankSkip
			push 0x00
			push bytesPerCluster
			push clusterBufferPtr
			call MemFill
		.BlankSkip:

		; copy data from the cluster buffer to the buffer address specified
		push chunkSize
		push clusterBufferPtr
		push address
		call MemCopy

		; write the cluster
		push clusterBufferPtr
		push sectorsPerCluster
		push sector
		push partitionNumber
		call PartitionWrite

		; adjust the pointer into the ouput buffer to prepare it for the next write
		mov eax, chunkSize
		add address, eax

		; get the next cluster in the chain
		push cluster
		push FAT1
		push partitionNumber
		call FAT16ClusterNextGet
		mov cluster, eax

	jmp .ChainWriteLoop

	.Done:

	; if we get here, all went as planned!
	push clusterBufferPtr
	call MemDispose

	mov eax, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16ClusterFreeFirstGet:
	; Returns the first free cluster in the FAT
	;
	;  input:
	;	Partition number
	;
	;  output:
	;	EAX - Cluster number
	;	EBX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]

	; allocate local variables
	sub esp, 28
	%define clusterFree							dword [ebp - 4]
	%define partitionSlotPtr					dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define FATStart							dword [ebp - 16]
	%define FATSectors							dword [ebp - 20]
	%define clusterCount						dword [ebp - 24]
	%define clustersChecked						dword [ebp - 28]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		; if we get here, there was
		mov eax, 0
		mov ebx, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; zero the cluster counts
	mov clusterFree, 0
	mov clustersChecked, 0

	; load some data from the cache so we can do our maths
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.FAT1]
	mov FATStart, eax

	mov eax, dword [tPartitionInfo.clusterCount]
	; we add 2 here to compensate for the first two FAT entries which are invalid for file use
	add eax, 2
	mov clusterCount, eax

	mov ecx, dword [tPartitionInfo.sectorsPerFAT]

	.ClusterLoop:
		mov FATSectors, ecx
		; read the sector into the buffer
		push sectorBufferPtr
		push 1
		push FATStart
		push partitionNumber
		call PartitionRead

		; count how many free clusters there are in this sector of the FAT
		mov ecx, 256
		.ClusterCountLoop:
			mov eax, 256
			sub eax, ecx
			shl eax, 1
			add eax, sectorBufferPtr
			mov bx, word [eax]
			cmp bx, 0
			jne .NotFree
				; if we get here, this cluster was free
				mov ebx, clustersChecked
				mov clusterFree, ebx
				jmp .ClusterCountLoopDone
			.NotFree:
			inc clustersChecked

			; see if we've checked enough clusters yet
			mov eax, clustersChecked
			cmp eax, clusterCount
			je .ClusterCountLoopDone
		loop .ClusterCountLoop

		inc FATStart
	mov ecx, FATSectors
	loop .ClusterLoop


	.ClusterCountLoopDone:
	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; all is well that ends well
	mov eax, clusterFree
	cmp eax, 0
	jne .SkipErrorSet
		; if we get here, no free cluster was found; ergo, we set an error saying so
		mov ebx, kErrPartitionFull
		jmp .Exit
	.SkipErrorSet:
	mov ebx, kErrNone

	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16ClusterFreeTotalGet:
	; Returns cluster stats for the partition specified
	;
	;  input:
	;	Partition number
	;
	;  output:
	;	EAX - Clusters free
	;	EBX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]

	; allocate local variables
	sub esp, 28
	%define clustersFree						dword [ebp - 4]
	%define partitionSlotPtr					dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define FATStart							dword [ebp - 16]
	%define FATSectors							dword [ebp - 20]
	%define clusterCount						dword [ebp - 24]
	%define clustersChecked						dword [ebp - 28]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; zero the cluster counts
	mov clustersFree, 0
	mov clustersChecked, 0

	; load some data from the cache so we can do our maths
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.FAT1]
	mov FATStart, eax

	mov eax, dword [tPartitionInfo.clusterCount]
	; we add 2 here to compensate for the first two FAT entries which are invalid for file use
	add eax, 2
	mov clusterCount, eax

	mov ecx, dword [tPartitionInfo.sectorsPerFAT]

	.ClusterLoop:
		mov FATSectors, ecx
		; read the sector into the buffer
		push sectorBufferPtr
		push 1
		push FATStart
		push partitionNumber
		call PartitionRead

		; count how many free clusters there are in this sector of the FAT
		mov ecx, 256
		.ClusterCountLoop:
			mov eax, 256
			sub eax, ecx
			shl eax, 1
			add eax, sectorBufferPtr
			mov bx, word [eax]
			cmp bx, 0
			jne .NotFree
				; if we get here, this cluster was free
				inc clustersFree
			.NotFree:
			inc clustersChecked

			; see if we've checked enough clusters yet
			mov eax, clustersChecked
			cmp eax, clusterCount
			je .ClusterCountLoopDone
		loop .ClusterCountLoop

		inc FATStart
	mov ecx, FATSectors
	loop .ClusterLoop


	.ClusterCountLoopDone:

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; all is well that ends well
	mov eax, clustersFree
	mov ebx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16ClusterNextGet:
	; Determines the next cluster in the chain
	;
	;  input:
	;	Partition number
	;	LBA sector number of FAT
	;	Cluster number of start of chain
	;
	;  output:
	;	EAX - Next cluster in the chain

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define FATLBA								dword [ebp + 12]
	%define cluster								dword [ebp + 16]

	; allocate local variables
	sub esp, 20
	%define sectorOffset						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define returnValue							dword [ebp - 16]
	%define thisSector							dword [ebp - 20]


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; get sector to be read based on the cluster number given
	push cluster
	call FAT16CalcTableElementFromCluster
	mov sectorOffset, eax
	mov bytePosition, ebx

	; read the sector into the buffer
	mov eax, FATLBA
	add eax, sectorOffset
	mov thisSector, eax
	push sectorBufferPtr
	push 1
	push thisSector
	push partitionNumber
	call PartitionRead

	; read and save the number of the next cluster in the chain
	mov esi, sectorBufferPtr
	add esi, bytePosition
	mov eax, 0
	mov ax, word [esi]
	mov returnValue, eax

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; load up the return value
	mov eax, returnValue


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16ClusterNextSet:
	; Sets the next cluster in the chain from the cluster specified
	;
	;  input:
	;	Partition number
	;	Cluster number to update
	;	Next cluster number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define updateCluster						dword [ebp + 12]
	%define nextCluster							dword [ebp + 16]

	; allocate local variables
	sub esp, 28
	%define partitionSlotPtr					dword [ebp - 4]
	%define sectorOffset						dword [ebp - 8]
	%define bytePosition						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define returnValue							dword [ebp - 20]
	%define thisSector							dword [ebp - 24]
	%define FATStart							dword [ebp - 28]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		; there was an error, so GEEEET TO DE CHOPPAAAH
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; load some data from the cache so we can do our maths
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.FAT1]
	mov FATStart, eax

	; get sector to be read based on the cluster number given
	push updateCluster
	call FAT16CalcTableElementFromCluster
	mov sectorOffset, eax
	mov bytePosition, ebx

	; read the sector into the buffer
	mov eax, FATStart
	add eax, sectorOffset
	mov thisSector, eax
	push sectorBufferPtr
	push 1
	push thisSector
	push partitionNumber
	call PartitionRead

	; read and save the number of the next cluster in the chain
	mov esi, sectorBufferPtr
	add esi, bytePosition
	mov eax, nextCluster
	mov word [esi], ax

	; write the buffer back to disk
	push sectorBufferPtr
	push 1
	push thisSector
	push partitionNumber
	call PartitionWrite

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; load up the return value
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16DirEntryMatchName:
	; Returns the address of a match for the item specified in the buffer specified
	;
	;  input:
	;	Pointer to string containing item name
	;	Pointer to buffer containing directory table
	;	Buffer size
	;
	;  output:
	;	AL - Result
	;		True - Match found
	;		False - Match not found
	;	ESI - Address at which match was found, or zero if none found

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]
	%define bufferPtr							dword [ebp + 12]
	%define bufferSize							dword [ebp + 16]

	; allocate local variables
	sub esp, 8
	%define colonPosition						dword [ebp - 4]
	%define bufferEnd							dword [ebp - 8]


	; format this item to match how it would appear in the directory table
	push path$
	call FATEncodeFilename

	; calculate the end of the buffer
	mov eax, bufferPtr
	add eax, bufferSize
	dec eax
	mov bufferEnd, eax

	; loop through the entries in the buffer and look for a match
	.MatchLoop:
		; see if what we have here matches the specified attribute; if not, we can skip to the next iteration now
		mov esi, bufferPtr
		mov eax, 0
		mov ax, word [tFATDirEntry.attributes]
		and eax, attributes
		cmp eax, attributes
		jne .NextIteration

		; if we get here, the attribute matched
		; now let's see if the filename matches
		push 11
		push bufferPtr
		push path$
		call MemCompare

		cmp edx, true
		je .LoopDone

		.NextIteration:
		add bufferPtr, 32
		mov eax, bufferEnd
		cmp bufferPtr, eax
	jb .MatchLoop

	; if we get here, no match was found
	mov al, false
	mov esi, 0
	jmp .Exit

	.LoopDone:
	mov al, true
	mov esi, bufferPtr


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16FATBackup:
	; Copies the working FAT (the first FAT) to any remaining spots in the FAT area
	;
	;  input:
	;	Partition number
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]

	; allocate local variables
	sub esp, 20
	%define FAT1								dword [ebp - 4]
	%define FAT2								dword [ebp - 8]
	%define sectorsPerFAT						dword [ebp - 12]
	%define partitionSlotPtr					dword [ebp - 16]
	%define sectorBufferPtr						dword [ebp - 20]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; load some data from the cache so we can do our maths
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.FAT1]
	mov FAT1, eax

	mov eax, dword [tPartitionInfo.FAT2]
	mov FAT2, eax

	mov eax, dword [tPartitionInfo.sectorsPerFAT]
	mov sectorsPerFAT, eax


	; force the first pass through the loop
	mov ecx, sectorsPerFAT

	.SectorCopyLoop:
		mov sectorsPerFAT, ecx

		; read a sector in from the first FAT
		push sectorBufferPtr
		push 1
		push FAT1
		push partitionNumber
		call PartitionRead

		; write the sector to the second FAT
		push sectorBufferPtr
		push 1
		push FAT2
		push partitionNumber
		call PartitionWrite

		; set up the sector values for the next pass
		inc FAT1
		inc FAT2

		mov ecx, sectorsPerFAT
	loop .SectorCopyLoop

	; clean up your toys when you're done
	push sectorBufferPtr
	call MemDispose


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16FileCreate:
	; Creates a new file at the path specified
	;
	;  input:
	;	filepath string for the new file
	;	initial length of file
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret





section .text
FAT16FileDelete:
	; Deletes the file specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string (without drive letter/partition number)
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 28
	%define cluster								dword [ebp - 4]
	%define bufferPtr							dword [ebp - 8]
	%define bufferSize							dword [ebp - 12]
	%define matchPtr							dword [ebp - 16]
	%define copyStart							dword [ebp - 20]
	%define lastEntryPtr						dword [ebp - 24]
	%define directoryChainStart					dword [ebp - 28]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry

	; see if there was an error
	cmp eax, kErrNone
	jne .Exit

	; save some important stuff from this call
	mov directoryChainStart, ebx
	mov bufferSize, ecx
	mov matchPtr, esi
	mov bufferPtr, edi

	; the address of the element is held in ESI from the above call
	; now we have to get the cluster at which the item resides
	mov eax, 0
	mov ax, word [tFATDirEntry.startingCluster]
	mov cluster, eax

	; mark the directory entry as deleted
	mov [esi], byte 0xE5

	; write the directory chain back to disk
	push bufferPtr
	push bufferSize
	push directoryChainStart
	push partitionNumber
	call FAT16ChainWrite

	; delete this cluster chain
	push cluster
	push partitionNumber
	call FAT16ChainDelete

	; drop that RAM like it's hot
	push bufferPtr
	call MemDispose

	; update the extra FATs
	push partitionNumber
	call FAT16FATBackup

	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16FileInfoAccessedGet:
	; Returns the date of last access for the specified file
	;
	;  input:
	;	Partition number
	;	Path string of file
	;
	;  output:
	;	EAX (Upper 16 bits) - Year
	;	AL - Month
	;	AH - Day
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 8
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry
	mov bufferPtr, edi

	; check for errors
	cmp eax, kErrNone
	je .NoError
		; if we get here, there was one o' them thar pesky errors
		mov edx, eax
		jmp .Exit
	.NoError:

	; get the modification date from the directory entry
	mov eax, 0
	mov ax, word [tFATDirEntry.lastAccessDate]

	; convert the date
	push eax
	call FATDecodeDate
	mov outputDate, eax

	; dispose of the memory block we were returned
	push bufferPtr
	call MemDispose

	; load the return value and exit
	mov eax, outputDate


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16FileInfoCreatedGet:
	; Returns the date and time of creation for the specified file
	;
	;  input:
	;	Partition number
	;	Path string of file
	;
	;  output:
	;	EAX (Upper 16 bits) - Year
	;	AL - Month
	;	AH - Day
	;	EBX (Upper 16 bits) - Hours
	;	BH - Minutes
	;	BL - Seconds
	;	EDX - Error code

	push ebp
	mov ebp, esp


	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 21
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]
	%define outputTime							dword [ebp - 12]
	%define lastModTime							dword [ebp - 16]
	%define lastModDate							dword [ebp - 20]
	%define seconds								byte [ebp - 21]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry
	mov bufferPtr, edi

	; check for errors
	cmp eax, kErrNone
	je .NoError
		; if we get here, there was one o' them thar pesky errors
		mov edx, eax
		jmp .Exit
	.NoError:

	; get the creation time from the directory entry
	mov eax, 0
	mov ax, word [tFATDirEntry.createTime]
	mov lastModTime, eax

	mov al, byte [tFATDirEntry.createTimeSeconds]
	mov seconds, al

	; get the creation date from the directory entry
	mov eax, 0
	mov ax, word [tFATDirEntry.createDate]
	mov lastModDate, eax

	; convert the date
	push lastModDate
	call FATDecodeDate
	mov outputDate, eax

	; convert the time
	push lastModTime
	call FATDecodeTime
	mov outputTime, eax

	; dispose of the memory block we were returned
	push bufferPtr
	call MemDispose

	; load the return value and exit
	mov eax, outputDate
	mov ebx, outputTime
	mov bl, seconds


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16FileInfoModifiedGet:
	; Returns the date and time of last modification for the specified file
	;
	;  input:
	;	Partition number
	;	Path string of file
	;
	;  output:
	;	EAX (Upper 16 bits) - Year
	;	AL - Month
	;	AH - Day
	;	EBX (Upper 16 bits) - Hours
	;	BH - Minutes
	;	BL - Seconds
	;	EDX - Error code

	push ebp
	mov ebp, esp


	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 20
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]
	%define outputTime							dword [ebp - 12]
	%define lastModTime							dword [ebp - 16]
	%define lastModDate							dword [ebp - 20]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry
	mov bufferPtr, edi

	; check for errors
	cmp eax, kErrNone
	je .NoError
		; if we get here, there was one o' them thar pesky errors
		mov edx, eax
		jmp .Exit
	.NoError:

	; get the modification time from the directory entry
	mov eax, 0
	mov ax, word [tFATDirEntry.lastModifiedTime]
	mov lastModTime, eax

	; get the modification date from the directory entry
	mov eax, 0
	mov ax, word [tFATDirEntry.lastModifiedDate]
	mov lastModDate, eax

	; convert the date
	push lastModDate
	call FATDecodeDate
	mov outputDate, eax

	; convert the time
	push lastModTime
	call FATDecodeTime
	mov outputTime, eax

	; dispose of the memory block we were returned
	push bufferPtr
	call MemDispose

	; load the return value and exit
	mov eax, outputDate
	mov ebx, outputTime


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16FileInfoSizeGet:
	; Gets the size of the file specified
	;
	;  input:
	;	Partition number
	;	Path string of file
	;
	;  output:
	;	EAX - Length of file
	;	EDX - Error code

	push ebp
	mov ebp, esp


	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define size								dword [ebp - 4]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry

	; check for errors
	cmp eax, kErrNone
	je .NoError
		; if we get here, there was one o' them thar pesky errors
		mov edx, eax
		jmp .Exit
	.NoError:

	; get the size from the directory entry
	mov eax, dword [tFATDirEntry.size]
	mov size, eax

	; dispose of the memory block we were returned
	push edi
	call MemDispose

	; load the return value and exit
	mov eax, size


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16FileInfoSizeSet:
	; Sets the size of the file specified
	; Note: If necessary, additional clusters will be allocated or disposed of to meet the size requested
	;
	;  input:
	;	path string of file
	;	new length of file
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret





section .text
FAT16FileLoad:
	; Loads the file specified at the address specified using FAT16 standards
	;
	;  input:
	;	Partition number
	;	Pointer to file path string (without drive letter/partition number)
	;	Address at which to load file
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]

	; allocate local variables
	sub esp, 8
	%define cluster								dword [ebp - 4]
	%define size								dword [ebp - 8]


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry

	; see if there was an error
	cmp eax, kErrNone
	jne .Exit

	; the address of the element is held in ESI from the above call
	; now we have to get the cluster at which the item resides
	mov eax, 0
	mov ax, word [tFATDirEntry.startingCluster]
	mov cluster, eax

	; and now get the size
	mov ebx, dword [tFATDirEntry.size]
	mov size, ebx

	; dispose of the memory block we were returned
	push edi
	call MemDispose


	; load that cluster chain into memory
	push address
	push size
	push cluster
	push partitionNumber
	call FAT16ChainRead


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16FileStore:
	; Stores the range of memory specified as a file at the FAT16 path specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string (without drive letter/partition number)
	;	Address at which file data resides
	;	Length of file data
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]
	%define length								dword [ebp + 20]

	; allocate local variables
	sub esp, 40
	%define cluster								dword [ebp - 4]
	%define size								dword [ebp - 8]
	%define clustersRequired					dword [ebp - 12]
	%define sectorsPerCluster					dword [ebp - 16]
	%define dirEntryPtr							dword [ebp - 20]
	%define dirBufferPtr						dword [ebp - 24]
	%define dirBufferCluster					dword [ebp - 28]
	%define dirError							dword [ebp - 32]
	%define FATLBA								dword [ebp - 36]
	%define dataArea							dword [ebp - 40]


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; load cached partition data
	mov eax, [tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [tPartitionInfo.dataArea]
	mov dataArea, eax

	mov eax, [tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax


	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionNumber
	call FAT16PathToDirEntry
	mov dirError, eax
	mov dirEntryPtr, esi
	mov dirBufferPtr, edi
	mov dirBufferCluster, ebx
jmp $
	; see how many clusters this file will need to be stored
	push length
	push sectorsPerCluster
	call FAT16CalcClustersNeeded
	mov clustersRequired, eax

	; see if the item was found... or not
	mov eax, dirError
	cmp eax, kErrNone
	jne .AWildErrorAppears
		; if we get here, that means the item already exists and we will be overwriting it

		; the address of the element is held in ESI from the call to FAT16PathToDirEntry, so we restore that pointer here
		mov esi, dirEntryPtr

		; now we have to get the cluster at which the item resides
		mov eax, 0
		mov ax, word [tFATDirEntry.startingCluster]
		mov cluster, eax

		; and now get the size
		mov ebx, dword [tFATDirEntry.size]
		mov size, ebx

		; we will need to modify the chain to reflect the new length
		push clustersRequired
		push cluster
		push FATLBA
		push partitionNumber
		call FAT16ChainResize

		jmp .WriteChain
	.AWildErrorAppears:


	; If we get here, there was some sort of error. Let's exit if it's not the one we want.
	cmp eax, kErrItemNotFound
	jne .Exit

	; if we get here, the error was "Item Not Found" so we need to create a new cluster chain to accomodate this file
mov edx, dirBufferPtr
jmp $

	; add the filename and info to the dir buffer



	
	.WriteChain:
	; write the cluster chain to disk
	push address
	push length
	push cluster
	push partitionNumber
	call FAT16ChainWrite

	; modify the dir entry to show the new size
	mov esi, dirEntryPtr
	mov eax, length
	mov dword [tFATDirEntry.size], eax

	; translate the cluster at which the dir entry resides into a sector address and write back to disk
	push dataArea
	push sectorsPerCluster
	push dirBufferCluster
	call FAT16CalcLBAClusterToSector

	push dirBufferPtr
	push 1
	push eax
	push partitionNumber
	call PartitionWrite


	; dispose of the memory block we were returned
	push dirBufferPtr
	call MemDispose

	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16FileWrite:
	; Writes data from memory to the file structure on disk
	;
	;  input:
	;	address of data in memory
	;	length of data to be written
	;	path string for file to which data will be written
	;	offset from beginning of file at which to start writing data
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret





section .text
FAT16ItemExists:
	; Tests if the item specified already exists
	;
	;  input:
	;
	;  output:
	;	AL - Result
	;		True - Item exists
	;		False - Item does not exist

	push ebp
	mov ebp, esp

	; define input parameters
	%define element								dword [ebp + 8]

	; allocate local variables
	sub esp, 16
	%define partitionSlotPtr					dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]


	; do stuff here


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16PartitionCacheData:
	; Caches FAT16-specific data from sector 0 of the partition to the FS reserved section of this partiton's entry in the partitions list
	;
	;  input:
	;	Partition number
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define element								dword [ebp + 8]

	; allocate local variables
	sub esp, 16
	%define partitionSlotPtr					dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]


	; get the address of this element in the list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; allocate a sector buffer in which we can play
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error
	cmp edx, kErrNone
	je .SectorBufferAllocateOK
		mov eax, edx
		jmp .Exit
	.SectorBufferAllocateOK:
	mov sectorBufferPtr, eax

	; fill our buffer with the first sector of this partition
	push sectorBufferPtr
	push 1
	push 0
	push partitionNumber
	call PartitionRead

	; get some info from the sector we just loaded so we can find the FAT
	; save sectorsPerCluster for later
	mov esi, sectorBufferPtr
	mov eax, 0
	mov al, [tFAT16BPB.sectorsPerCluster]
	mov esi, partitionSlotPtr
	mov dword [tPartitionInfo.sectorsPerCluster], eax

	; calculate bytes per cluster
	shl eax, 9
	mov dword [tPartitionInfo.bytesPerCluster], eax

	; get starting LBA address for the first FAT
	; FAT1 = reservedSectors
	mov esi, sectorBufferPtr
	mov eax, 0
	mov ax, word [tFAT16BPB.reservedSectors]
	mov esi, partitionSlotPtr
	mov dword [tPartitionInfo.FAT1], eax

	; get sectors per FAT
	mov esi, sectorBufferPtr
	mov eax, 0
	mov ax, word [tFAT16BPB.sectorsPerFAT]
	mov esi, partitionSlotPtr
	mov dword [tPartitionInfo.sectorsPerFAT], eax

	; get starting LBA address for the second FAT
	; FAT2 = FAT1 + sectorsPerFAT
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.FAT1]
	add eax, dword [tPartitionInfo.sectorsPerFAT]
	mov dword [tPartitionInfo.FAT2], eax

	; get starting LBA address for the root directory
	; rootDir = reservedSectors + (FATCount * sectorsPerFAT)
	mov esi, sectorBufferPtr
	mov eax, 0
	mov ebx, 0
	mov al, byte [tFAT16BPB.FATCount]
	mov bx, word [tFAT16BPB.sectorsPerFAT]
	mul ebx
	add ax, word [tFAT16BPB.reservedSectors]
	mov esi, partitionSlotPtr
	mov dword [tPartitionInfo.rootDir], eax

	; save root directory entry count
	mov esi, sectorBufferPtr
	mov eax, 0
	mov ax, word [tFAT16BPB.rootDirectoryEntries]
	mov esi, partitionSlotPtr
	mov dword [tPartitionInfo.rootDirectoryEntries], eax

	; get starting LBA address for the data area
	; dataArea = rootDir + (rootDirectoryEntries * 32) / 512
	mov eax, dword [tPartitionInfo.rootDirectoryEntries]
	; shr eax, 4 is a combination of shl eax, 5 to multiply by 32 and shr eax, 9 to divide by 512
	shr eax, 4
	add eax, dword [tPartitionInfo.rootDir]
	mov dword [tPartitionInfo.dataArea], eax

	; calculate total number of clusters in this partition
	; total clusters = (totalsectors - dataarea + 1) / sectorsPerCluster
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.sectorCount]
	sub eax, dword [tPartitionInfo.dataArea]
	inc eax
	div dword [tPartitionInfo.sectorsPerCluster]
	mov dword [tPartitionInfo.clusterCount], eax

	; set the flag so that we know this partition has been cached in the future
	mov esi, partitionSlotPtr
	mov eax, 0
	bts eax, 0
	mov dword [tPartitionInfo.FSFlags], eax

	; if we get here, all went as planned!
	push sectorBufferPtr
	call MemDispose

	mov eax, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16PathCanonicalize:
	; Returns the proper form of the path specified according to FAT16 standards
	;
	;  input:
	;	Pointer to file path string
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]


	; make sure the string is all upper case
	push path$
	call StringCaseUpper

	; turn all / into \ (ASCII 47 into ASCII 92)
	push 92
	push 47
	push path$
	call StringCharReplace


	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16PathToDirEntry:
	; Returns a buffer containing the directory entry containing the item specified by the path given
	;
	;  input:
	;	Partition number
	;	File path string
	;
	;  output:
	;	ESI - Address of matching directory entry
	;	EDI - Buffer address
	;	EAX - Error code
	;	EBX - Starting cluster of chain which is loaded into buffer
	;	ECX - Buffer size in bytes

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]

	; allocate local variables
	sub esp, 60
	%define partitionSlotPtr					dword [ebp - 4]
	%define itemCount							dword [ebp - 8]
	%define FAT1								dword [ebp - 12]
	%define searchSector						dword [ebp - 16]
	%define dirBufferSizeBytes					dword [ebp - 20]
	%define dirBufferSizeSectors				dword [ebp - 24]
	%define dataArea							dword [ebp - 28]
	%define currentPathItem						dword [ebp - 32]
	%define dirBufferPtr						dword [ebp - 36]
	%define sectorsPerCluster					dword [ebp - 40]
	%define cluster								dword [ebp - 44]
	%define size								dword [ebp - 48]
	%define nameScratch$						60						; 12 byte string


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax

	mov eax, [tPartitionInfo.FAT1]
	mov FAT1, eax

	mov eax, [tPartitionInfo.rootDir]
	mov searchSector, eax

	mov eax, [tPartitionInfo.dataArea]
	mov dataArea, eax


	; zero out the important stuff
	mov cluster, 0

	; make sure the path conforms to FAT16 standards
	push path$
	call FAT16PathCanonicalize

	; see how many "words" (items) are in this path
	push .seperatorSlash$
	push path$
	call StringWordCount

	; see if the number of items is zero, save the value for later if not
	mov itemCount, ecx
	cmp ecx, null
	jne .ItemCheckGood
		; if we get here, this path has no meat on its bones
		mov eax, kErrPathInvalid
		mov ebx, 0
		mov ecx, 0
		mov esi, 0
		mov edi, 0
		jmp .Exit
	.ItemCheckGood:

	; calculate the size of the root directory in sectors
	mov esi, partitionSlotPtr
	mov eax, dword [tPartitionInfo.rootDirectoryEntries]
	shr eax, 4
	mov dirBufferSizeSectors, eax

	; set up a loop to step through the items in the path
	mov currentPathItem, 0
	.itemLoop:
		inc currentPathItem

		; calculate how many bytes are needed for the buffer
		mov eax, dirBufferSizeSectors
		shl eax, 9
		mov dirBufferSizeBytes, eax

		; allocate a buffer for the root directory
		push dirBufferSizeBytes
		push dword 1
		call MemAllocate

		; exit if there was an error
		cmp edx, kErrNone
		je .DirectoryBufferAllocateOK
			mov eax, edx
			jmp .Exit
		.DirectoryBufferAllocateOK:
		mov dirBufferPtr, eax

		; get the first item in the list
		mov edi, ebp
		sub edi, nameScratch$
		push edi
		push currentPathItem
		push .seperatorSlash$
		push path$
		call StringWordGet

		; load the directory into RAM for searching
		push dirBufferPtr
		push dirBufferSizeSectors
		push searchSector
		push partitionNumber
		call PartitionRead

		; do a search for this item and see if it exists
		push dirBufferSizeBytes
		push dirBufferPtr
		mov eax, ebp
		sub eax, nameScratch$
		push eax
		call FAT16DirEntryMatchName

		cmp al, true
		je .MatchFound
			; if we get here, there was no match
			mov eax, kErrItemNotFound
			mov ebx, 0
			mov ecx, 0
			mov esi, 0
			mov edi, 0
			jmp .Exit
		.MatchFound:

		; we've found a match; exit if we're on the last item in the path
		mov ecx, itemCount
		cmp currentPathItem, ecx
		je .LoopDone

		; once we get here, we have a match, but we're not at the end of the path; let's forge ahead
		; the address of the element is held in ESI from the above call
		; now we use that to calculate the cluster at which the item resides
		mov eax, 0
		mov ax, word [tFATDirEntry.startingCluster]
		mov cluster, eax

		; and now get the size
		mov ebx, dword [tFATDirEntry.size]
		mov size, ebx

		; make sure the cluster returned is valid
		push 0xFFEF
		push 0x0002
		push eax
		call RangeCheck
		cmp al, true
		je .ClusterOK
			; if we get here, the cluster indicates we've hit the end of the chain
			mov eax, kErrClusterChainEndUnexpected
			mov ebx, 0
			mov ecx, 0
			mov esi, 0
			mov edi, 0
			jmp .Exit
		.ClusterOK:

		; convert the cluster returned in EAX to a sector number
		; sector = (cluster - 2) * sectorsPerCluster + dataArea
		mov eax, cluster
		sub eax, 2
		mul sectorsPerCluster
		add eax, dataArea
		mov searchSector, eax

		; see how many clusters are in the chain of this item
		push cluster
		push FAT1
		push partitionNumber
		call FAT16ChainLength
		mul sectorsPerCluster
		mov dirBufferSizeSectors, eax

		; dispose of the buffer we were using since it's about to be re-allocated
		push dirBufferPtr
		call MemAllocate
	jmp .itemLoop

	.LoopDone:
	; set up our return values
	mov edi, dirBufferPtr
	mov eax, kErrNone
	mov ebx, cluster
	mov ecx, dirBufferSizeBytes


	.Exit:
	mov esp, ebp
	pop ebp
ret 8

section .data
.seperatorSlash$								dw 0092





section .text
FAT16ServiceHandler:
	; The FAT16 service routine called by external applications
	;
	;  input:
	;	Command number
	;	Parameter 1
	;	Parameter 2
	;	Parameter 3
	;	Parameter 4
	;
	;  output:
	;	EDX - Driver response

	push ebp
	mov ebp, esp

	; define input parameters
	%define command								dword [ebp + 8]
	%define parameter1							dword [ebp + 12]
	%define parameter2							dword [ebp + 16]
	%define parameter3							dword [ebp + 20]
	%define parameter4							dword [ebp + 24]


	cmp command, kDriverInit
	jne .NotInit
		; set this dispatch routine as the handler for all the partition types we handle
		; FAT16 "small" volume
		push 0x04
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; FAT16 "large" volume
		push 0x06
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Windows 95 FAT16 volume
		push 0x0E
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Hidden FAT16 volume
		push 0x16
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Hidden Windows 95 FAT16 volume
		push 0x1E
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		jmp .Success
	.NotInit:


	; every function after this point expects the partition number in parameter 1,
	; so we can optimize a bit here and make sure the partition info is cached before proceeding

	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; see if the FAT16-specific data from this partition has been cached yet and cache it if not
	bt dword [tPartitionInfo.FSFlags], 0
	jc .AlreadyCached
		push parameter1
		call FAT16PartitionCacheData
	.AlreadyCached:


	; do driver-y things here
	cmp command, kDriverFileDelete
	jne .NotFileDelete
		push parameter2
		push parameter1
		call FAT16FileDelete
		jmp .Success
	.NotFileDelete:

	cmp command, kDriverFileLoad
	jne .NotFileLoad
		push parameter3
		push parameter2
		push parameter1
		call FAT16FileLoad
		jmp .Success
	.NotFileLoad:

	cmp command, kDriverFileStore
	jne .NotFileStore
		push parameter4
		push parameter3
		push parameter2
		push parameter1
		call FAT16FileStore
		jmp .Success
	.NotFileStore:

	cmp command, kDriverFileInfoAccessedGet
	jne .NotFileAccessedGet
		push parameter2
		push parameter1
		call FAT16FileInfoAccessedGet
		jmp .Success
	.NotFileAccessedGet:

	cmp command, kDriverFileInfoCreatedGet
	jne .NotFileCreatedGet
		push parameter2
		push parameter1
		call FAT16FileInfoCreatedGet
		jmp .Success
	.NotFileCreatedGet:

	cmp command, kDriverFileInfoModifiedGet
	jne .NotFileModifiedGet
		push parameter2
		push parameter1
		call FAT16FileInfoModifiedGet
		jmp .Success
	.NotFileModifiedGet:

	cmp command, kDriverFileInfoSizeGet
	jne .NotFileSizeGet
		push parameter2
		push parameter1
		call FAT16FileInfoSizeGet
		jmp .Success
	.NotFileSizeGet:

	.Success:
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 20





section .text
FAT32ServiceHandler:
	; The FAT32 service routine called by external applications
	;
	;  input:
	;	Command number
	;	Parameter 1
	;	Parameter 2
	;	Parameter 3
	;	Parameter 4
	;
	;  output:
	;	Driver response

	push ebp
	mov ebp, esp

	; define input parameters
	%define command								dword [ebp + 8]
	%define parameter1							dword [ebp + 12]
	%define parameter2							dword [ebp + 16]
	%define parameter3							dword [ebp + 20]
	%define parameter4							dword [ebp + 24]


	; do driver-y things here
	cmp command, kDriverInit
	jne .NotInit
		; init - set FAT32 handler addresses
		push 0x0B
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT32ServiceHandler

		push 0x0C
		push dword [tSystem.listFSHandlers]
		call LMElementAddressGet
		mov dword [esi], FAT32ServiceHandler
	.NotInit:


	mov esp, ebp
	pop ebp
ret 20





section .text
FATDecodeDate:
	; Extracts the month, day, and year from the numeric representation as found in a file's directory entry
	;
	;  input:
	;	Numeric representation of date
	;
	;  output:
	;	EAX (Upper 16 bits) - Year
	;	AL - Month
	;	AH - Day

	push ebp
	mov ebp, esp

	; define input parameters
	%define numeric								dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define month								byte [ebp - 1]
	%define day									byte [ebp - 2]
	%define year								word [ebp - 4]


	; extract day
	mov eax, numeric
	and al, 0x1F
	mov day, al

	; extract month
	mov eax, numeric
	shr eax, 5
	and al, 0x0F
	mov month, al

	; extract year
	mov eax, numeric
	shr eax, 9
	and ax, 0x7F
	add ax, 1980
	mov year, ax

	; set return values and exit
	mov eax, 0
	mov ax, year
	shl eax, 16
	mov al, month
	mov ah, day


	mov esp, ebp
	pop ebp
ret 4





section .text
FATDecodeTime:
	; Extracts hours, minutes, and seconds from the numeric representation as found in a file's directory entry
	;
	;  input:
	;	Numeric representation of time
	;
	;  output:
	;	EAX (Upper 16 bits) - Hours
	;	AH - Minutes
	;	AL - Seconds

	push ebp
	mov ebp, esp

	; define input parameters
	%define numeric								dword [ebp + 8]

	; allocate local variables
	sub esp, 3
	%define hours								byte [ebp - 1]
	%define minutes								byte [ebp - 2]
	%define seconds								byte [ebp - 3]


	; extract seconds
	mov eax, numeric
	and al, 0x1F
	mov bl, 2
	mul bl
	mov seconds, al

	; extract minutes
	mov eax, numeric
	shr eax, 5
	and al, 0x3F
	mov minutes, al

	; extract hours
	mov eax, numeric
	shr eax, 11
	and al, 0x1F
	mov hours, al

	; set return values and exit
	mov eax, 0
	mov al, hours
	shl eax, 16
	mov ah, minutes
	mov al, seconds


	mov esp, ebp
	pop ebp
ret 4





section .text
FATEncodeDate:
	; Encodes the month, day, and year specified into the numeric representation found in a file's directory entry
	;
	;  input:
	;	Month
	;	Day
	;	Year
	;
	;  output:
	;	AX - Encoded date
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define month								dword [ebp + 8]
	%define day									dword [ebp + 12]
	%define year								dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define numeric								dword [ebp - 4]


	; validate parameters
	push 12
	push 1
	push month
	call RangeCheck
	cmp al, true
	jne .Fail

	push 31
	push 1
	push day
	call RangeCheck
	cmp al, true
	jne .Fail

	push 2107
	push 1980
	push year
	call RangeCheck
	cmp al, true
	jne .Fail


	; process year
	sub year, 1980
	and year, 127
	mov eax, year
	mov numeric, eax

	; process month
	and month, 15
	mov eax, month
	shl numeric, 4
	or numeric, eax

	; process day
	and day, 31
	mov eax, day
	shl numeric, 5
	or numeric, eax


	; set return values
	mov eax, numeric
	mov edx, kErrNone
	jmp .Exit

	.Fail:
	mov edx, kErrInvalidParameter


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FATEncodeFilename:
	; Formats the specified filename as it would appear in a FAT directory table
	;
	;  input:
	;	Pointer to file path string in an 11 byte buffer
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]

	; allocate local variables
	sub esp, 32
	%define nameScratchPtr						12						; 12 byte string
	%define extScratchPtr						24						; 12 byte string
	%define dotPosition							dword [ebp - 28]
	%define itemCount							dword [ebp - 32]


	; get word count
	push .seperatorDot$
	push path$
	call StringWordCount
	mov itemCount, ecx

	; get file name
	mov eax, ebp
	sub eax, nameScratchPtr
	push eax
	push 1
	push .seperatorDot$
	push path$
	call StringWordGet

	; pad the name with spaces to 8 characters
	push 8
	push 32
	mov eax, ebp
	sub eax, nameScratchPtr
	push eax
	call StringPadRight

	; get file extension
	mov eax, ebp
	sub eax, extScratchPtr
	push eax
	push 2
	push .seperatorDot$
	push path$
	call StringWordGet
	
	; pad the name with spaces to 3 characters
	push 3
	push 32
	mov eax, ebp
	sub eax, extScratchPtr
	push eax
	call StringPadRight

	; recombine the name and extension back to the source buffer
	push 8
	push path$
	mov eax, ebp
	sub eax, nameScratchPtr
	push eax
	call MemCopy

	push 3
	mov eax, path$
	add eax, 8
	push eax
	mov eax, ebp
	sub eax, extScratchPtr
	push eax
	call MemCopy


	.Exit:
	mov esp, ebp
	pop ebp
ret 4

section .data
.seperatorDot$									dw 0046





section .text
FATEncodeTime:
	; Encodes the hours, minutes, and seconds specified into the numeric representation found in a file's directory entry
	;
	;  input:
	;	Hours
	;	Minutes
	;	Seconds
	;
	;  output:
	;	AX - Encoded time
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define hours								dword [ebp + 8]
	%define minutes								dword [ebp + 12]
	%define seconds								dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define numeric								dword [ebp - 4]


	; validate parameters
	push 23
	push 0
	push hours
	call RangeCheck
	cmp al, true
	jne .Fail

	push 59
	push 0
	push minutes
	call RangeCheck
	cmp al, true
	jne .Fail

	push 59
	push 0
	push seconds
	call RangeCheck
	cmp al, true
	jne .Fail


	; process hours
	and hours, 31
	mov eax, hours
	mov numeric, eax

	; process minutes
	and minutes, 63
	mov eax, minutes
	shl numeric, 6
	or numeric, eax

	; process seconds
	shr seconds, 1
	and seconds, 31
	mov eax, seconds
	shl numeric, 5
	or numeric, eax


	; set return values
	mov eax, numeric
	mov edx, kErrNone
	jmp .Exit

	.Fail:
	mov edx, kErrInvalidParameter


	.Exit:
	mov esp, ebp
	pop ebp
ret 12
