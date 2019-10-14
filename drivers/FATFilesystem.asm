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
; FAT16CalcLBAClusterToSector			Returns the LBA address of the sector pointed to by the cluster number specified
; FAT16CalcSpaceNeeded					Returns the amount of space required to store a file of the specified size in both clusters and sectors
; FAT16CalcTableElementFromCluster		Translates the specified FAT table entry into offsets from the start of the FAT table
; FAT16ChainDelete						Deletes the cluster chain specified
; FAT16ChainGrow						Extends the cluster chain specified to the length specified
; FAT16ChainLength						Returns the length in clusters of the cluster chain specified
; FAT16ChainRead						Returns a buffer containing the requested cluster chain
; FAT16ChainResize						Resizes the cluster chain specified to the length specified
; FAT16ChainShrink						Shortens the cluster chain specified to the length specified
; FAT16ChainWrite						Writes the buffer specified to the cluster chain specified
; FAT16ClusterFreeFirstGet				Returns the first free cluster in the FAT
; FAT16ClusterFreeTotalGet				Returns the current number of free clusters on the partition specified
; FAT16ClusterNextGet					Determines the next cluster in the chain
; FAT16ClusterNextSet					Sets the next cluster in the chain from the cluster specified
; FAT16EntryBuild						Encodes the entry data passed at the address specified
; FAT16FATBackup						Copies the working FAT (the first FAT) to any remaining spots in the FAT area
; FAT16FileWrite						Writes data from memory to the file structure on disk
; FAT16ItemCount						Returns the number of items at the directory specified
; FAT16ItemDelete						Deletes the file specified
; FAT16ItemExists						Tests if the item specified already exists
; FAT16ItemInfoAccessedGet				Returns the date and time of last access for the specified file
; FAT16ItemInfoCreatedGet				Returns the date and time of creation for the specified file
; FAT16ItemInfoModifiedGet				Returns the date and time of last modification for the specified file
; FAT16ItemInfoSizeGet					Gets the size of the file specified
; FAT16ItemLoad							Returns a buffer containing the item specified
; FAT16ItemMatch						Searches the buffer specified for a match to the item specified
; FAT16ItemNew							Creates a new file or directory at the path specified
; FAT16ItemStore						Stores the range of memory specified as a file at the FAT16 path specified
; FAT16PartitionCacheData				Caches FAT16-specific data from sector 0 of the partition to the FS reserved section of this partiton's entry in the partitions list
; FAT16PartitionInfo					Returns space information on the specified partition
; FAT16PathCanonicalize					Returns the proper form of the path specified according to FAT16 standards
; FAT16ServiceHandler					The FAT16 service routine called by external applications

; FAT32ServiceHandler					The FAT32 service routine called by external applications

; FATDecodeDate							Extracts the month, day, and year from the numeric representation as found in a file's directory entry
; FATDecodeTime							Extracts the hours, minutes, and seconds from the numeric representation as found in a file's directory entry
; FATEncodeDate							Encodes the month, day, and year specified into the numeric representation found in a file's directory entry
; FATEncodeFilename						Formats the specified filename as it would appear in a FAT directory table
; FATEncodeTime							Encodes the hours, minutes, and seconds specified into the numeric representation found in a file's directory entry





%include "include/FAT Filesystem defines.inc"

%include "include/boolean.inc"
%include "include/errors.inc"
%include "include/globals.inc"
%include "include/memory.inc"
%include "include/lists.inc"
%include "include/numbers.inc"
%include "include/storage.inc"
%include "include/strings.inc"





bits 32





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
FAT16CalcSpaceNeeded:
	; Returns the amount of space required to store a file of the specified size in both clusters and sectors
	;
	;  input:
	;	Sectors per cluster
	;	File size
	;
	;  output:
	;	EAX - Clusters needed
	;	EBX - Sectors needed

	push ebp
	mov ebp, esp

	; define input parameters
	%define sectorsPerCluster					dword [ebp + 8]
	%define fileSize							dword [ebp + 12]


	; calculate sectors
	mov ebx, 512
	mov eax, fileSize
	mov edx, 0
	div ebx

	cmp edx, 0
	je .Next
		inc eax

	.Next:
	mov ebx, eax

	; calculate clusters
	mov ecx, sectorsPerCluster
	shl ecx, 9
	mov eax, fileSize
	mov edx, 0
	div ecx

	cmp edx, 0
	je .Exit
		inc eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





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
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp


	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]

	; allocate local variables
	sub esp, 24
	%define partitionNumber						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define thisSector							dword [ebp - 16]
	%define lastSector							dword [ebp - 20]
	%define FATLBA								dword [ebp - 24]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov bytePosition, ebx

		; EAX already holds the sector offset, so we add FATLBA to it to calculate the sector number to be read
		add eax, FATLBA
		mov thisSector, eax

		; see if this sector is the same as the one already in the buffer and skip loading if so
		cmp lastSector, eax
		je .LoadSkip
			; if we get here, the sectors are different, so we need to save the current one
			push sectorBufferPtr
			push 1
			push lastSector
			push partitionNumber
			call SMPartitionWrite

			; update lastSector
			mov eax, thisSector
			mov lastSector, eax

			; read the sector into the buffer
			push sectorBufferPtr
			push 1
			push thisSector
			push partitionNumber
			call SMPartitionRead
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
		call CheckRange

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
	call SMPartitionWrite

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
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]
	%define newLength							dword [ebp + 16]

	; allocate local variables
	sub esp, 52
	%define bytePosition						dword [ebp - 4]
	%define clusterCount						dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define clusterBufferPtr					dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]
	%define newCluster							dword [ebp - 28]
	%define lastCluster							dword [ebp - 32]
	%define partitionNumber						dword [ebp - 36]
	%define FATLBA								dword [ebp - 40]
	%define dataArea							dword [ebp - 44]
	%define sectorsPerCluster					dword [ebp - 48]
	%define bytesPerCluster						dword [ebp - 52]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	mov eax, [esi + tPartitionInfo.dataArea]
	mov dataArea, eax

	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	mov eax, [esi + tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax


	; allocate a cluster buffer
	; This block, like all blocks doled out by the Memory Manager, will be zeroed automatically.
	; This is perfect for null-ing the new clusters we add to the chain.
	mov eax, [esi + tPartitionInfo.bytesPerCluster]
	push eax
	push dword 1
	call MemAllocate

	; see if there was an error, save the returned pointer if not
	cmp edx, kErrNone
	jne .Exit
	mov clusterBufferPtr, eax

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
		mov bytePosition, ebx

		; EAX already holds the sector offset, so we add FATLBA to it to calculate the sector number to be read
		add eax, FATLBA
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
			call SMPartitionRead
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
		call CheckRange

	; if the above call returned true, we're not yet at the end of the chain
	cmp al, true
	je .ClusterLoop

	.GrowLoop:
		; once we get here, we're at the end of the chain - let's start growing!
		push partitionSlotPtr
		call FAT16ClusterFreeFirstGet
		mov newCluster, eax

		; check for errors
		cmp edx, kErrNone
		jne .Exit


		; zero out the newly assigned cluster here
		; Q: Why do you null new clusters added to the chain? Isn't that inefficient??
		; A: Ehh, maybe a little. But it makes it easier to handle growing a directory; otherwise 
		; the caller would have to walk the chain we just grew and zero any new clusters it finds.
		; which we just added. While we're this deep in the grow operation anyway, we may as well
		; just do it here and save the caller some time down the road.

		; see where we need to write on disk
		push dataArea
		push sectorsPerCluster
		push lastCluster
		call FAT16CalcLBAClusterToSector

		; write a zeroed cluster to disk
		push clusterBufferPtr
		push sectorsPerCluster
		push eax
		push partitionNumber
		call SMPartitionWrite


		; update the chain to point to the proper next cluster
		push newCluster
		push lastCluster
		push partitionSlotPtr
		call FAT16ClusterNextSet

		; terminate the chain
		push 0xFFFF
		push newCluster
		push partitionSlotPtr
		call FAT16ClusterNextSet

		; lastCluster = newCluster
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
ret 12





section .text
FAT16ChainLength:
	; Returns the length in clusters of the cluster chain specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Cluster number of start of chain
	;
	;  output:
	;	EAX - Chain length
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]

	; allocate local variables
	sub esp, 28
	%define bytePosition						dword [ebp - 4]
	%define clusterCount						dword [ebp - 8]
	%define sectorBufferPtr						dword [ebp - 12]
	%define thisSector							dword [ebp - 16]
	%define lastSector							dword [ebp - 20]
	%define FATLBA								dword [ebp - 24]
	%define partitionNumber						dword [ebp - 28]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


	; allocate a sector buffer
	push dword 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; zero the cluster count
	mov clusterCount, 0

	; make lastSector impossibly large to guard against false positives
	mov lastSector, 0xFFFFFFFF

	.ClusterLoop:
		inc clusterCount

		; The max number of clusters possible in FAT16 is 0xFFFC. It's bad news if the chain is longer than the partition itself!
		mov edx, kErrClusterChainBad
		cmp clusterCount, 0xFFFD
		je .Exit

		; get sector to be read based on the cluster number given
		push cluster
		call FAT16CalcTableElementFromCluster
		mov bytePosition, ebx

		; EAX already holds the sector offset, so we add FATLBA to it to calculate the sector number to be read
		add eax, FATLBA
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
			call SMPartitionRead
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
		call CheckRange

		; if the above call returned false, we're at the end of the file
		cmp al, false
		je .Done

	jmp .ClusterLoop

	.Done:
	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	mov eax, clusterCount
	mov edx, kErrNone

	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16ChainRead:
	; Returns a buffer containing the requested cluster chain
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain (zero for root directory)
	;
	;  output:
	;	ESI - Address of buffer containing the chain requested
	;	ECX - Buffer size
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]

	; allocate local variables
	sub esp, 36
	%define dataArea							dword [ebp - 4]
	%define sectorsPerCluster					dword [ebp - 8]
	%define rootDirLBA							dword [ebp - 12]
	%define rootDirSectorCount					dword [ebp - 16]
	%define bytesPerCluster						dword [ebp - 20]
	%define bufferPtr							dword [ebp - 24]
	%define bufferSize							dword [ebp - 28]
	%define bufferPtrOffset						dword [ebp - 32]
	%define partitionNumber						dword [ebp - 36]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.rootDirSize]
	mov bufferSize, eax

	mov eax, [esi + tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	mov eax, [esi + tPartitionInfo.dataArea]
	mov dataArea, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	mov eax, [esi + tPartitionInfo.rootDir]
	mov rootDirLBA, eax

	mov eax, [esi + tPartitionInfo.rootDirSectorCount]
	mov rootDirSectorCount, eax

	mov eax, [esi + tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax

	; I can't wait to get to FAT32 where this will no longer be an issue :/
	cmp cluster, 0
	jne .NotRootDir
		; if we get here, it's the root directory being requested
		; allocate enough RAM to hold it
		push bufferSize
		push dword 1
		call MemAllocate

		; see if there was an error, if not save the pointer
		cmp edx, kErrNone
		jne .Exit
		mov bufferPtr, eax

		; load the directory into RAM
		push eax
		push rootDirSectorCount
		push rootDirLBA
		push partitionNumber
		call SMPartitionRead

		mov esi, bufferPtr
		mov ecx, bufferSize
		mov edx, kErrNone
		jmp .Exit
	.NotRootDir:

	; if we get here, a chain was requested
	push cluster
	push partitionSlotPtr
	call FAT16ChainLength

	; bytes = clusters * bytesPerCluster
	mov ebx, eax
	mul bytesPerCluster
	mov bufferSize, eax

	; allocate a buffer of the appropriate length for this chain
	push eax
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov bufferPtr, eax

	; see if there was an error
	cmp edx, kErrNone
	jne .Exit
	mov bufferPtr, eax

	; zero the offset pointer
	mov bufferPtrOffset, 0

	; read this chain in a loop
	.ChainReadLoop:
		; make sure the cluster returned is valid
		push 0xFFEF
		push 0x0002
		push cluster
		call CheckRange
		cmp al, true
		jne .Done

		; get sector LBA from cluster number, store in EAX
		push dataArea
		push sectorsPerCluster
		push cluster
		call FAT16CalcLBAClusterToSector

		; calculate the actual address
		mov esi, bufferPtr
		add esi, bufferPtrOffset

		; load the cluster into RAM
		push esi
		push sectorsPerCluster
		push eax
		push partitionNumber
		call SMPartitionRead

		; adjust the offset pointer
		mov esi, bufferPtrOffset
		add esi, bytesPerCluster
		mov bufferPtrOffset, esi

		; get the next cluster in the chain
		push cluster
		push partitionSlotPtr
		call FAT16ClusterNextGet
		mov cluster, eax
	jmp .ChainReadLoop

	.Done:
	mov esi, bufferPtr
	mov ecx, bufferSize
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16ChainResize:
	; Resizes the cluster chain specified to the length specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define chainStart							dword [ebp + 12]
	%define newLength							dword [ebp + 16]


	; see how long the chain is now
	push chainStart
	push partitionSlotPtr
	call FAT16ChainLength

	; if current length > desired length, shrink the chain
	cmp eax, newLength
	jbe .NoShrink
		push newLength
		push chainStart
		push partitionSlotPtr
		call FAT16ChainShrink
		jmp .Exit
	.NoShrink:

	; if current length < desired length, grow the chain
	cmp eax, newLength
	jae .NoGrow
		push newLength
		push chainStart
		push partitionSlotPtr
		call FAT16ChainGrow
	.NoGrow:


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16ChainShrink:
	; Shortens the cluster chain specified to the length specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain
	;	New chain length
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]
	%define newLength							dword [ebp + 16]

	; allocate local variables
	sub esp, 33
	%define sectorOffset						dword [ebp - 4]
	%define bytePosition						dword [ebp - 8]
	%define clusterCount						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define thisSector							dword [ebp - 20]
	%define lastSector							dword [ebp - 24]
	%define partitionNumber						dword [ebp - 28]
	%define FATLBA								dword [ebp - 32]
	%define sectorWriteFlag						byte [ebp - 33]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


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
			call SMPartitionRead
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
		call CheckRange

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
ret 12

.WriteIfNecessary:
	; see if there's anything to write back to disk
	cmp sectorWriteFlag, true
	jne .NoNeedToWrite
		; there's stuff to write, so let's do it
		push sectorBufferPtr
		push 1
		push lastSector
		push partitionNumber
		call SMPartitionWrite
		mov sectorWriteFlag, false
	.NoNeedToWrite:
ret





section .text
FAT16ChainWrite:
	; Writes the buffer specified to the cluster chain specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Starting cluster for chain (zero for root directory)
	;	Address of buffer containing the chain requested
	;	Buffer size
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]
	%define bufferPtr							dword [ebp + 16]
	%define bufferSize							dword [ebp + 20]

	; allocate local variables
	sub esp, 36
	%define dataArea							dword [ebp - 4]
	%define sectorsPerCluster					dword [ebp - 8]
	%define rootDirLBA							dword [ebp - 12]
	%define rootDirSectorCount					dword [ebp - 16]
	%define bytesPerCluster						dword [ebp - 20]
	%define bufferPtrOffset						dword [ebp - 24]
	%define clustersNeeded						dword [ebp - 28]
	%define sectorsNeeded						dword [ebp - 32]
	%define partitionNumber						dword [ebp - 36]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	mov eax, [esi + tPartitionInfo.dataArea]
	mov dataArea, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	mov eax, [esi + tPartitionInfo.rootDir]
	mov rootDirLBA, eax

	mov eax, [esi + tPartitionInfo.rootDirSectorCount]
	mov rootDirSectorCount, eax

	mov eax, [esi + tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax

	; see how many clusters are required for this amount of data
	push bufferSize
	push sectorsPerCluster
	call FAT16CalcSpaceNeeded
	mov clustersNeeded, eax
	mov sectorsNeeded, ebx

	cmp cluster, 0
	jne .NotRootDir
		; if we get here, we need to write to the root directory

		; first see if the amount being written will exceed the size of the root directory
		mov eax, rootDirSectorCount
		cmp ebx, eax
		jng .InRange
			; if we get here, the amount of bytes we were told to write won't actually fit in the root directory's space on disk
			; error and leave
			mov edx, kErrValueTooHigh
			jmp .Exit
		.InRange:

		; write the data
		push bufferPtr
		push sectorsPerCluster
		push rootDirLBA
		push partitionNumber
		call SMPartitionWrite

		jmp .Done
	.NotRootDir:
	; if we get here, we're working with a cluster chain

	; we will first need to modify the chain to reflect the new length
	push clustersNeeded
	push cluster
	push partitionSlotPtr
	call FAT16ChainResize

	; zero the offset pointer
	mov bufferPtrOffset, 0

	.ChainWriteLoop:
		; get sector LBA from cluster number, store in EAX
		push dataArea
		push sectorsPerCluster
		push cluster
		call FAT16CalcLBAClusterToSector

		; calculate the actual address
		mov esi, bufferPtr
		add esi, bufferPtrOffset

		; write the cluster
		push esi
		push sectorsPerCluster
		push eax
		push partitionNumber
		call SMPartitionWrite

		; adjust the offset pointer
		mov esi, bufferPtrOffset
		add esi, bytesPerCluster
		mov bufferPtrOffset, esi

		; get the next cluster in the chain
		push cluster
		push partitionSlotPtr
		call FAT16ClusterNextGet
		mov cluster, eax

		; make sure the cluster returned is valid
		push 0xFFEF
		push 0x0002
		push cluster
		call CheckRange
		cmp al, true
		jne .Done
	jmp .ChainWriteLoop

	.Done:
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16ClusterFreeFirstGet:
	; Returns the first free cluster in the FAT
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;
	;  output:
	;	EAX - Cluster number
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]

	; allocate local variables
	sub esp, 28
	%define clusterFree							dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]
	%define FATLBA								dword [ebp - 12]
	%define FATSectors							dword [ebp - 16]
	%define clusterCount						dword [ebp - 20]
	%define clustersChecked						dword [ebp - 24]
	%define partitionNumber						dword [ebp - 28]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.clusterCount]
	; we add 2 here to compensate for the first two FAT entries which are invalid for file use
	add eax, 2
	mov clusterCount, eax

	mov eax, dword [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, dword [esi + tPartitionInfo.sectorsPerFAT]
	mov FATSectors, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, save buffer address if not
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; zero the cluster counts
	mov clusterFree, 0
	mov clustersChecked, 0

	; catalyze the loop
	mov ecx, FATSectors

	.ClusterLoop:
		mov FATSectors, ecx
		; read the sector into the buffer
		push sectorBufferPtr
		push 1
		push FATLBA
		push partitionNumber
		call SMPartitionRead

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

		inc FATLBA
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
		mov edx, kErrPartitionFull
		jmp .Exit
	.SkipErrorSet:
	mov edx, kErrNone

	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16ClusterFreeTotalGet:
	; Returns the current number of free clusters on the partition specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;
	;  output:
	;	EAX - Clusters free
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]

	; allocate local variables
	sub esp, 28
	%define clustersFree						dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]
	%define FATLBA								dword [ebp - 12]
	%define FATSectors							dword [ebp - 16]
	%define clusterCount						dword [ebp - 20]
	%define clustersChecked						dword [ebp - 24]
	%define partitionNumber						dword [ebp - 28]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.clusterCount]
	; we add 2 here to compensate for the first two FAT entries which are invalid for file use
	add eax, 2
	mov clusterCount, eax

	mov eax, dword [esi + tPartitionInfo.sectorsPerFAT]
	mov FATSectors, eax

	mov eax, dword [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; zero the cluster counts
	mov clustersFree, 0
	mov clustersChecked, 0

	; The Catalyst. Not by Linkin Park.
	mov ecx, FATSectors

	.ClusterLoop:
		mov FATSectors, ecx
		; read the sector into the buffer
		push sectorBufferPtr
		push 1
		push FATLBA
		push partitionNumber
		call SMPartitionRead

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

		inc FATLBA
	mov ecx, FATSectors
	loop .ClusterLoop


	.ClusterCountLoopDone:

	; dispose of the sector buffer
	push sectorBufferPtr
	call MemDispose

	; all is well that ends well
	mov eax, clustersFree
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16ClusterNextGet:
	; Determines the next cluster in the chain
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Cluster number of start of chain
	;
	;  output:
	;	EAX - Next cluster in the chain
	;	EDX - Next cluster in the chain

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define cluster								dword [ebp + 12]

	; allocate local variables
	sub esp, 20
	%define bytePosition						dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]
	%define returnValue							dword [ebp - 12]
	%define partitionNumber						dword [ebp - 16]
	%define FATLBA								dword [ebp - 20]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; get sector to be read based on the cluster number given
	push cluster
	call FAT16CalcTableElementFromCluster
	mov bytePosition, ebx

	; EAX already holds the sector offset, so we add FATLBA to it to calculate the sector number to be read
	add eax, FATLBA
	push sectorBufferPtr
	push 1
	push eax
	push partitionNumber
	call SMPartitionRead

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
ret 8





section .text
FAT16ClusterNextSet:
	; Sets the next cluster in the chain from the cluster specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Cluster number to update
	;	Next cluster number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define updateCluster						dword [ebp + 12]
	%define nextCluster							dword [ebp + 16]

	; allocate local variables
	sub esp, 20
	%define bytePosition						dword [ebp - 4]
	%define sectorBufferPtr						dword [ebp - 8]
	%define thisSector							dword [ebp - 12]
	%define FATLBA								dword [ebp - 16]
	%define partitionNumber						dword [ebp - 20]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


	; allocate a sector buffer
	push 512
	push dword 1
	call MemAllocate

	; see if there was an error, if not save the pointer
	cmp edx, kErrNone
	jne .Exit
	mov sectorBufferPtr, eax

	; get sector to be read based on the cluster number given
	push updateCluster
	call FAT16CalcTableElementFromCluster
	mov bytePosition, ebx

	; EAX already holds the sector offset, so we add FATLBA to it to calculate the sector number to be read
	add eax, FATLBA
	mov thisSector, eax
	push sectorBufferPtr
	push 1
	push thisSector
	push partitionNumber
	call SMPartitionRead

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
	call SMPartitionWrite

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
FAT16EntryBuild:
	; Encodes the entry data passed at the address specified
	;
	;  input:
	;	Pointer to the entry (destination write address)
	;	Entry name
	;	Entry attributes
	;	Entry create seconds
	;	Entry create time
	;	Entry create date
	;	Entry last access date
	;	Entry last modified time
	;	Entry last modified date
	;	Entry starting cluster
	;	Entry size
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define entryPtr							dword [ebp + 8]
	%define entryName							dword [ebp + 12]
	%define entryAttributes						dword [ebp + 16]
	%define entryCreateSeconds					dword [ebp + 20]
	%define entryCreateTime						dword [ebp + 24]
	%define entryCreateDate						dword [ebp + 28]
	%define entryLastAccessDate					dword [ebp + 32]
	%define entryLastModifiedTime				dword [ebp + 36]
	%define entryLastModifiedDate				dword [ebp + 40]
	%define entryStartingCluster				dword [ebp + 44]
	%define entrySize							dword [ebp + 48]

	; allocate local variables
	sub esp, 16
	%define itemPtr								dword [ebp - 4]
	%define item$								dword [ebp - 16]		; a 12 byte string to temporarily hold the item name


	; make itemPtr point to item$
	mov itemPtr, esp

	; right now we only support 8.3 names, so here we check that the name isn't over 11 characters
	push entryName
	call StringLength
	cmp eax, 11
	jng .NameOK
		mov edx, kErrInvalidParameter
		jmp .Exit
	.NameOK:

	; wipe this area for the string
	push 0
	push 12
	push itemPtr
	call MemFill

	push 11
	push itemPtr
	push entryName
	call MemCopy

	; format this item to match how it would appear in the directory table
	push itemPtr
	call FATEncodeFilename

	; now we write everything to the buffer!
	; set the pointer to this item
	mov esi, entryPtr

	; now set all the fields for the new item
	mov eax, entryAttributes
	mov byte [esi + tFATDirEntry.attributes], al

	mov eax, entryCreateSeconds
	mov byte [esi + tFATDirEntry.createTimeSeconds], al

	mov eax, entryCreateTime
	mov word [esi + tFATDirEntry.createTime], ax

	mov eax, entryCreateDate
	mov word [esi + tFATDirEntry.createDate], ax

	mov eax, entryLastAccessDate
	mov word [esi + tFATDirEntry.lastAccessDate], ax

	mov eax, entryLastModifiedTime
	mov word [esi + tFATDirEntry.lastModifiedTime], ax

	mov eax, entryLastModifiedDate
	mov word [esi + tFATDirEntry.lastModifiedDate], ax

	mov eax, entryStartingCluster
	mov word [esi + tFATDirEntry.startingCluster], ax

	mov eax, entrySize
	mov dword [esi + tFATDirEntry.size], 0

	; And finally, copy the item name. We do this last since the other routines determine whether or not an entry
	; is occupied by checking the name field for a null character, and writing the name last minimizes the window
	; for error should a power failure occur precisely during this operation.
	push 11
	push esi
	push itemPtr
	call MemCopy


	; all is well
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 44





section .text
FAT16FATBackup:
	; Copies the working FAT (the first FAT) to the backup FAT (the second FAT)
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]

	; allocate local variables
	sub esp, 24
	%define FATLBA								dword [ebp - 4]
	%define BackupFATLBA						dword [ebp - 8]
	%define sectorsPerFAT						dword [ebp - 12]
	%define sectorBufferPtr						dword [ebp - 16]
	%define partitionNumber						dword [ebp - 20]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.FAT2]
	mov BackupFATLBA, eax

	mov eax, [esi + tPartitionInfo.FAT1]
	mov FATLBA, eax

	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	mov eax, dword [esi + tPartitionInfo.sectorsPerFAT]
	mov sectorsPerFAT, eax


	; get the address of this partition's slot in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LM_Internal_ElementAddressGet
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


	; force the first pass through the loop
	mov ecx, sectorsPerFAT

	.SectorCopyLoop:
		mov sectorsPerFAT, ecx

		; read a sector in from the first FAT
		push sectorBufferPtr
		push 1
		push FATLBA
		push partitionNumber
		call SMPartitionRead

		; write the sector to the second FAT
		push sectorBufferPtr
		push 1
		push BackupFATLBA
		push partitionNumber
		call SMPartitionWrite

		; set up the sector values for the next pass
		inc FATLBA
		inc BackupFATLBA

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
FAT16ItemCount:
	; Returns the number of items in the directory specified which have the attribute bits specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
	;	Attributes to match
	;
	;  output:
	;	EAX - Number of matching items, or zero if error
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define attributes							dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define itemCount							dword [ebp - 4]


	; get the item specified loaded into a buffer
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad

	; exit if error
	cmp edx, kErrNone
	jne .Exit

	; Make sure what we loaded is a directory; we can't count the number of items in a file!
	and eax, kFATAttributeDirectory
	cmp eax, kFATAttributeDirectory
	mov edx, kErrNotADirectory
	jne .Exit

	; zero the counter
	mov itemCount, 0

	; enter a loop to count the items in the buffer until a null one is reached
	.BufferLoop:
		mov al, [esi]

		; if this is the end of the directory data, we're done!
		cmp al, 0x00
		je .BufferLoopDone

		; if this is a deleted entry, we ignore it and keep going
		cmp al, 0xE5
		je .Iterate

		; if we get here, see if the attribute matches
		mov eax, attributes
		mov bl, [esi + tFATDirEntry.attributes]
		and bl, al
		cmp bl, al
		jne .Iterate

		; If we get here, the attribute matched. Items +1!
		inc itemCount

		.Iterate:
		; Adjust counters, pointers, and bears. Oh, my!
		sub ecx, 32 
		add esi, 32
	loop .BufferLoop

	.BufferLoopDone:
	mov eax, itemCount
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16ItemDelete:
	; Deletes the file specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 28
	%define cluster								dword [ebp - 4]
	%define dirBufferPtr						dword [ebp - 8]
	%define dirBufferCluster					dword [ebp - 12]
	%define dirBufferSize						dword [ebp - 16]
	%define item$								dword [ebp - 20]
	%define parentPath$							dword [ebp - 24]
	%define matchPtr							dword [ebp - 28]


	; create a duplicate on the stack of the given path
	push path$
	call StringLength

	inc eax
	sub esp, eax
	mov parentPath$, esp
	push eax
	push parentPath$
	push path$
	call MemCopy


	; get the parent path
	push parentPath$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push parentPath$
	call StringLength
	add eax, parentPath$
	inc eax
	mov item$, eax

	; load the parent path into a buffer
	push parentPath$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov dirBufferSize, ecx
	mov dirBufferCluster, ebx
	mov dirBufferPtr, esi

	; if there was an error, we don't need to go any further
	cmp edx, kErrNone
	jne .Exit

	; search for the item
	push ecx
	push esi
	push item$
	call FAT16ItemMatch
	mov matchPtr, esi
	cmp al, true
	je .ItemFound
		; if we get here, the item already exists
		mov edx, kErrItemNotFound
		jmp .Exit
	.ItemFound:

	; the address of the match is held in ESI from the above call
	; now we have to get the cluster at which the item resides
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.startingCluster]
	mov cluster, eax


	; get the attribute so that we can check if this is a directory to make sure it's empty before deleting
	mov al, byte [esi + tFATDirEntry.attributes]
	and al, kFATAttributeDirectory
	cmp al, kFATAttributeDirectory
	jne .NotADir
		; if we get here, we're deleting a directory; see how many items are in it
		push dword 0x00
		push path$
		push partitionSlotPtr
		call FAT16ItemCount

		; prepare the error code and pointer for the next few tests
		mov edx, kErrDirectoryNotEmpty
		mov esi, matchPtr

		; if there are more than two items, we can easily exit right now
		cmp eax, 2
		jg .Exit

		; if we get here, there are only two entries, ("." and "..") so we can proceed and delete the directory anyway
	.NotADir:


	; mark the directory entry as deleted
	mov [esi], byte 0xE5

	; write the directory chain back to disk
	push dirBufferSize
	push dirBufferPtr
	push dirBufferCluster
	push partitionSlotPtr
	call FAT16ChainWrite

	; delete the item's cluster chain
	push cluster
	push partitionSlotPtr
	call FAT16ChainDelete

	; drop that RAM like it's hot
	push dirBufferPtr
	call MemDispose

	; sync the FATs
	push partitionSlotPtr
	call FAT16FATBackup

	; no errors in sight!
	mov edx, kErrNone

	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16ItemExists:
	; Tests if the item specified already exists
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	File path string
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 8
	%define errorReturned						dword [ebp - 4]
	%define item$								dword [ebp - 8]


	; get the parent path of this item
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov item$, eax

	; get info for the parent
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad

	; if there was an error, we don't need to go any further
	cmp edx, kErrNone
	jne .Exit

	; do a search for this item and see if it exists
	push ecx
	push esi
	push item$
	call FAT16ItemMatch
	mov errorReturned, edx

	; always clean up your toys
	push dirBufferPtr
	call MemDispose
	jmp .Exit

	mov edx, errorReturned



	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16ItemInfoAccessedGet:
	; Returns the date of last access for the specified file
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
	;
	;  output:
	;	EAX (Upper 16 bits) - Year
	;	AL - Month
	;	AH - Day
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 12
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]
	%define itemPtr								dword [ebp - 12]


	; turn path$ into its parent path
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov itemPtr, eax

	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov bufferPtr, esi

	; check for errors
	cmp edx, kErrNone
	jne .Exit

	; do a search for the item and see if it exists
	push ecx
	push esi
	push itemPtr
	call FAT16ItemMatch
	cmp al, true
	jne .Exit

	; get the modification date from the directory entry
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.lastAccessDate]

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
FAT16ItemInfoCreatedGet:
	; Returns the date and time of creation for the specified file
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
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
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 21
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]
	%define outputTime							dword [ebp - 12]
	%define lastModTime							dword [ebp - 16]
	%define itemPtr								dword [ebp - 20]
	%define seconds								byte [ebp - 21]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax

	; turn path$ into its parent path
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov itemPtr, eax

	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov bufferPtr, esi

	; check for errors
	cmp edx, kErrNone
	jne .Exit

	; do a search for the item and see if it exists
	push ecx
	push esi
	push itemPtr
	call FAT16ItemMatch
	cmp al, true
	jne .Exit

	; get the creation time from the directory entry
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.createTime]
	mov lastModTime, eax

	mov al, byte [esi + tFATDirEntry.createTimeSeconds]
	mov seconds, al

	; get the creation date from the directory entry
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.createDate]

	; convert the date
	push eax
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
FAT16ItemInfoModifiedGet:
	; Returns the date and time of last modification for the specified file
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
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
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 20
	%define bufferPtr							dword [ebp - 4]
	%define outputDate							dword [ebp - 8]
	%define outputTime							dword [ebp - 12]
	%define lastModTime							dword [ebp - 16]
	%define itemPtr								dword [ebp - 20]


	; turn path$ into its parent path
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov itemPtr, eax

	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov bufferPtr, esi

	; check for errors
	cmp edx, kErrNone
	jne .Exit

	; do a search for the item and see if it exists
	push ecx
	push esi
	push itemPtr
	call FAT16ItemMatch
	cmp al, true
	jne .Exit

	; get the modification time from the directory entry
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.lastModifiedTime]
	mov lastModTime, eax

	; get the modification date from the directory entry
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.lastModifiedDate]

	; convert the date
	push eax
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
FAT16ItemInfoSizeGet:
	; Gets the size of the file specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
	;
	;  output:
	;	ECX - Length of file
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 8
	%define size								dword [ebp - 4]
	%define itemPtr								dword [ebp - 8]


	; turn path$ into its parent path
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov itemPtr, eax

	; use the path to get the starting cluster of the cluster chain that is this file
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov bufferPtr, esi

	; check for errors
	cmp edx, kErrNone
	jne .Exit

	; do a search for the item and see if it exists
	push ecx
	push esi
	push itemPtr
	call FAT16ItemMatch
	cmp al, true
	jne .Exit

	; get the size from the directory entry
	mov eax, dword [esi + tFATDirEntry.size]
	mov size, eax

	; dispose of the memory block we were returned
	push edi
	call MemDispose

	; load the return value and exit
	mov ecx, size


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FAT16ItemLoad:
	; Returns a buffer containing the directory entry containing the item specified by the path given
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	File path string
	;
	;  output:
	;	ESI - Buffer address
	;	EDI - Actual size of item loaded into buffer
	;	EAX - Attributes of item loaded into buffer
	;	EBX - Starting cluster of chain which is loaded into buffer, or zero if root directory
	;	ECX - Buffer size in bytes
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 28
	%define dirBufferPtr						dword [ebp - 4]
	%define cluster								dword [ebp - 8]
	%define size								dword [ebp - 12]
	%define parentPath$							dword [ebp - 16]
	%define item$								dword [ebp - 20]
	%define rootDirSize							dword [ebp - 24]
	%define attributes							dword [ebp - 28]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.rootDirSize]
	mov rootDirSize, eax

	; zero out the important stuff
	mov cluster, 0

	; see how many "words" (items) are in this path
	push .seperatorSlash$
	push path$
	call StringWordCount

	cmp ecx, 0
	jne .ItemCountNonzero
		; if we get here the path has zero items, so load the root directory into a buffer and return
		push dword 0
		push partitionSlotPtr
		call FAT16ChainRead

		; time to get outta here!
		mov eax, rootDirSize
		mov size, eax
		jmp .Success
	.ItemCountNonzero:

	; if we get here, there's more than one item, so we need to shorten the path and recurse
	; create a duplicate on the stack of the given path
	push path$
	call StringLength

	inc eax
	sub esp, eax
	mov parentPath$, esp
	push eax
	push parentPath$
	push path$
	call MemCopy

	; get the parent path of this item
	push parentPath$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push parentPath$
	call StringLength
	add eax, parentPath$
	inc eax
	mov item$, eax

	; recurse now to get info for this item
	push parentPath$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov dirBufferPtr, esi

	; if there was an error, we don't need to go any further
	cmp edx, kErrNone
	jne .Exit

	; do a search for this item and see if it exists
	push ecx
	push esi
	push item$
	call FAT16ItemMatch
	cmp al, true
	jne .Fail

	; the address of the element is held in ESI from the above call
	; now we use that to calculate the cluster at which the item resides
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.startingCluster]
	mov cluster, eax

	; and now get the size
	mov eax, dword [esi + tFATDirEntry.size]
	mov size, eax

	; and now get the attribute
	mov eax, dword [esi + tFATDirEntry.attributes]
	mov attributes, eax

	; dispose of the buffer we were using since it's about to be re-allocated
	push dirBufferPtr
	call MemDispose

	; load that cluster chain into memory
	push cluster
	push partitionSlotPtr
	call FAT16ChainRead
	cmp edx, kErrNone
	jne .Fail

	.Success:
	; set up return values and exit
	mov eax, attributes
	mov ebx, cluster
	mov edx, kErrNone
	mov edi, size
	jmp .Exit

	.Fail:
	; if we get here, there was an error
	; dispose of buffer
	push dirBufferPtr
	call MemDispose

	; set return values
	mov esi, 0
	mov edi, 0
	mov eax, 0
	mov ebx, 0
	mov ecx, 0
	mov edx, kErrPathInvalid


	.Exit:
	mov esp, ebp
	pop ebp
ret 8

section .data
.seperatorSlash$								dw 0092





section .text
FAT16ItemMatch:
	; Searches the buffer specified for a match to the item specified
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
	;	ESI - Address at which match was found, or address of first free slot (if available - zero if not)

	push ebp
	mov ebp, esp

	; define input parameters
	%define inputPath$							dword [ebp + 8]
	%define bufferPtr							dword [ebp + 12]
	%define bufferSize							dword [ebp + 16]

	; allocate local variables
	sub esp, 8
	%define path$								dword [ebp - 4]
	%define bufferEnd							dword [ebp - 8]


	; create a duplicate on the stack of the given path
	sub esp, 11
	mov path$, esp
	push 11
	push path$
	push inputPath$
	call MemCopy

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
		; see if the current spot in the buffer holds a null
		mov esi, bufferPtr
		mov al, byte [esi]
		cmp al, 0
		je .LoopDone

		; see if the filename matches
		push 11
		push bufferPtr
		push path$
		call MemCompare

		cmp edx, true
		je .MatchFound

		.NextIteration:
		add bufferPtr, 32
		mov eax, bufferEnd
		cmp bufferPtr, eax
	jb .MatchLoop

	; if we get here, we ran into the end of the buffer
	; zero ESI to convey there's no free slot here
	mov esi, 0

	.LoopDone:
	; if we get here, no match was found
	mov al, false
	jmp .Exit

	.MatchFound:
	mov al, true
	mov esi, bufferPtr


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FAT16ItemNew:
	; Creates a new empty file or directory at the path specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Path for new item
	;	Attributes for new item
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define attributes							dword [ebp + 16]

	; allocate local variables
	sub esp, 40
	%define cluster								dword [ebp - 4]
	%define bytesPerCluster						dword [ebp - 8]
	%define parentPath$							dword [ebp - 12]
	%define item$								dword [ebp - 16]
	%define dirBufferPtr						dword [ebp - 20]
	%define dirBufferCluster					dword [ebp - 24]
	%define dirBufferSize						dword [ebp - 28]
	%define newEntryPtr							dword [ebp - 32]
	%define createDate							dword [ebp - 36]
	%define createTime							dword [ebp - 40]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.bytesPerCluster]
	mov bytesPerCluster, eax

	; see if there's a free cluster first; if there's not, no sense in going any further!
	push partitionSlotPtr
	call FAT16ClusterFreeFirstGet
	cmp edx, kErrNone
	jne .Exit
	mov cluster, eax

	; create a duplicate on the stack of the given path
	push path$
	call StringLength

	; leave some extra room for the padding we'll be doing on the item name later
	inc eax
	sub esp, eax
	mov parentPath$, esp
	push eax
	push parentPath$
	push path$
	call MemCopy

	; get the parent path of this item
	push parentPath$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push parentPath$
	call StringLength
	add eax, parentPath$
	inc eax
	mov item$, eax

	.LoadAttempt:
	; load the parent path into a buffer
	push parentPath$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov dirBufferSize, ecx
	mov dirBufferCluster, ebx
	mov dirBufferPtr, esi

	; if there was an error, we don't need to go any further
	cmp edx, kErrNone
	jne .Exit

	; do a search for this item and see if it already exists to make sure we're not overwriting anything
	push ecx
	push esi
	push item$
	call FAT16ItemMatch

	cmp al, false
	je .CreateItem
		; if we get here, the item already exists
		mov edx, kErrItemAlreadyExists
		jmp .Exit
	.CreateItem:

	; the above call will leave ESI set to the first free spot in the buffer, or zero if no slots were available
	; let's see which one we got here
	cmp esi, 0
	jne .EntryCreateOK
		; If we get here, there was no room for a new entry. How we handle this depends whether or not this is the root directory.
		cmp dirBufferCluster, 0
		jne .TryChainGrow
			; if we get here, this is the root directory, AND it's full. Guess we're OOL.
			mov edx, kErrRootDirectoryFull
			jmp .Exit
		.TryChainGrow:
		; If we get here, we're not in the root dir. Let's try growing the chain.

		; get the current length of this cluster chain
		push dirBufferCluster
		push partitionSlotPtr
		call FAT16ChainLength

		; exit if error
		cmp edx, kErrNone
		jne .Exit

		; add one to the length value stored in EAX from the above call
		inc eax

		; grow the chain
		push eax
		push dirBufferCluster
		push partitionSlotPtr
		call FAT16ChainGrow

		; exit if error
		cmp edx, kErrNone
		jne .Exit

		; and now, load the thing again
		jmp .LoadAttempt
	.EntryCreateOK:


	mov newEntryPtr, esi

	; encode the creation time
	mov eax, 0
	mov al, [tSystem.seconds]
	push eax
	mov al, [tSystem.minutes]
	push eax
	mov al, [tSystem.hours]
	push eax
	call FATEncodeTime
	mov createTime, eax

	; encode the creation date
	mov eax, 0
	mov al, [tSystem.year]
	add eax, 2000
	push eax
	mov eax, 0
	mov al, [tSystem.day]
	push eax
	mov al, [tSystem.month]
	push eax
	call FATEncodeDate
	mov createDate, eax

	; build the entry
	push size
	push cluster
	push createDate
	push createTime
	push createDate
	push createDate
	push createTime
	push 0
	push attributes
	push item$
	push newEntryPtr
	call FAT16EntryBuild

	; write the directory buffer back to disk to save the changed size
	push dirBufferSize
	push dirBufferPtr
	push dirBufferCluster
	push partitionSlotPtr
	call FAT16ChainWrite

	; dispose of the memory block we were returned
	push dirBufferPtr
	call MemDispose

	; mark the free cluster we got earlier to be the start and end of this chain
	push dword 0xFFFF
	push cluster
	push partitionSlotPtr
	call FAT16ClusterNextSet

	; check the specified attribute to see if this was a directory we just created
	mov eax, attributes
	and eax, kFATAttributeDirectory
	cmp eax, kFATAttributeDirectory
	jne .NotADir
		; If we get here, we just made a folder; we have to set up an empty structure containing the . and .. entries which DOS will expect.

		; first, we load the chain, which at this point will be a single cluster long
		push cluster
		push partitionSlotPtr
		call FAT16ChainRead
		mov dirBufferPtr, esi

		; now we zero the cluster to eliminate all junk data
		push 0
		push bytesPerCluster
		push esi
		call MemFill

		; now create the . entry
		push dword 0
		push cluster
		push createDate
		push createTime
		push dword 0
		push dword 0
		push dword 0
		push dword 0
		push attributes
		push .dotEntry$
		push dirBufferPtr
		call FAT16EntryBuild

		; since EntryBuild() doesn't know how to deal with "." (as it rightly shouldn't) we have to 'cheat' here
		mov esi, dirBufferPtr
		mov eax, [.dotEntry$]
		mov byte [esi], al

		; temporarily adjust the pointer here for the next step
		add dirBufferPtr, 32

		; and finally, create the .. entry
		push dword 0
		push dirBufferCluster
		push createDate
		push createTime
		push dword 0
		push dword 0
		push dword 0
		push dword 0
		push attributes
		push .dotDotEntry$
		push dirBufferPtr
		call FAT16EntryBuild

		; cheating again here...
		mov esi, dirBufferPtr
		mov eax, [.dotDotEntry$]
		mov word [esi], ax

		; adjust the pointer back
		sub dirBufferPtr, 32

		; lastly, write the chain back
		push bytesPerCluster
		push dirBufferPtr
		push cluster
		push partitionSlotPtr
		call FAT16ChainWrite

	.NotADir:

	; sync the FATs
	push partitionSlotPtr
	call FAT16FATBackup

	; no errors here!
	mov ebx, cluster
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 12

section .data
.dotEntry$										dd 0x0000002E
.dotDotEntry$									dd 0x00002E2E





section .text
FAT16ItemStore:
	; Stores the range of memory specified as a file at the path specified
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;	Pointer to file path string
	;	Address at which file data resides
	;	Length of file data
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]
	%define length								dword [ebp + 20]

	; allocate local variables
	sub esp, 28
	%define cluster								dword [ebp - 4]
	%define sectorsPerCluster					dword [ebp - 8]
	%define item$								dword [ebp - 12]
	%define dirBufferPtr						dword [ebp - 16]
	%define dirBufferCluster					dword [ebp - 20]
	%define dirBufferSize						dword [ebp - 24]
	%define matchPtr							dword [ebp - 28]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.sectorsPerCluster]
	mov sectorsPerCluster, eax


	; zero out the important stuff
	mov cluster, 0

	; turn path$ into its parent path
	push path$
	call SMPathParentGet

	; set up a pointer to the last item referenced in the path
	push path$
	call StringLength
	add eax, path$
	inc eax
	mov item$, eax

	; recurse now to get info for this item
	push path$
	push partitionSlotPtr
	call FAT16ItemLoad
	mov dirBufferSize, ecx
	mov dirBufferCluster, ebx
	mov dirBufferPtr, esi


	; if there was an error, we don't need to go any further
	cmp edx, kErrNone
	jne .Exit

	; do a search for this item and see if it exists
	push ecx
	push esi
	push item$
	call FAT16ItemMatch

	cmp al, true
	je .OverwriteItem
		; if we get here, the item wasn't found
		mov edx, kErrItemNotFound
		jmp .Exit
	.OverwriteItem:

	; the address of the element is held in ESI from the above call, save it here
	mov matchPtr, esi

	; now we use that to calculate the cluster at which the item resides
	mov eax, 0
	mov ax, word [esi + tFATDirEntry.startingCluster]
	mov cluster, eax

	; set the new size
	mov eax, length
	mov dword [esi + tFATDirEntry.size], eax

	; update the time
	mov eax, 0
	mov al, [tSystem.seconds]
	push eax
	mov al, [tSystem.minutes]
	push eax
	mov al, [tSystem.hours]
	push eax
	call FATEncodeTime
	mov esi, matchPtr
	mov word [esi + tFATDirEntry.lastModifiedTime], ax

	; update the date
	mov eax, 0
	mov al, [tSystem.year]
	add eax, 2000
	push eax
	mov eax, 0
	mov al, [tSystem.day]
	push eax
	mov al, [tSystem.month]
	push eax
	call FATEncodeDate
	mov esi, matchPtr
	mov word [esi + tFATDirEntry.lastModifiedDate], ax

	; write the directory buffer back to disk to save the changed size
	push dirBufferSize
	push dirBufferPtr
	push dirBufferCluster
	push partitionSlotPtr
	call FAT16ChainWrite

	; dispose of the memory block we were returned
	push dirBufferPtr
	call MemDispose

	; see how many clusters this file will need to be stored, save into EAX
	push length
	push sectorsPerCluster
	call FAT16CalcSpaceNeeded

	; we will need to modify the chain to reflect the new length
	push eax
	push cluster
	push partitionSlotPtr
	call FAT16ChainResize

	.WriteChain:
	; write the cluster chain to disk
	push length
	push address
	push cluster
	push partitionSlotPtr
	call FAT16ChainWrite

	; sync the FATs
	push partitionSlotPtr
	call FAT16FATBackup

	; no errors here!
	mov edx, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FAT16PartitionCacheData:
	; Caches FAT16-specific data from sector 0 of the partition to the FS reserved section of this partiton's entry in the partitions list
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]

	; allocate local variables
	sub esp, 8
	%define sectorBufferPtr						dword [ebp - 4]
	%define partitionNumber						dword [ebp - 8]


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, [esi + tPartitionInfo.partitionNumber]
	mov partitionNumber, eax


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
	call SMPartitionRead

	; get some info from the sector we just loaded so we can find the FAT
	; save sectorsPerCluster for later
	mov esi, sectorBufferPtr
	mov edi, partitionSlotPtr
	mov eax, 0
	mov al, [esi + tFAT16BPB.sectorsPerCluster]
	mov dword [edi + tPartitionInfo.sectorsPerCluster], eax

	; calculate bytes per cluster
	shl eax, 9
	mov dword [edi + tPartitionInfo.bytesPerCluster], eax

	; get starting LBA address for the first FAT
	; FAT1 = reservedSectors
	mov eax, 0
	mov ax, word [esi + tFAT16BPB.reservedSectors]
	mov dword [edi + tPartitionInfo.FAT1], eax

	; get sectors per FAT
	mov eax, 0
	mov ax, word [esi + tFAT16BPB.sectorsPerFAT]
	mov dword [edi + tPartitionInfo.sectorsPerFAT], eax

	; get starting LBA address for the second FAT
	; FAT2 = FAT1 + sectorsPerFAT
	mov eax, dword [edi + tPartitionInfo.FAT1]
	add eax, dword [edi + tPartitionInfo.sectorsPerFAT]
	mov dword [edi + tPartitionInfo.FAT2], eax

	; get starting LBA address for the root directory
	; rootDir = reservedSectors + (FATCount * sectorsPerFAT)
	mov eax, 0
	mov ebx, 0
	mov edx, 0
	mov al, byte [esi + tFAT16BPB.FATCount]
	mov bx, word [esi + tFAT16BPB.sectorsPerFAT]
	mul ebx
	add ax, word [esi + tFAT16BPB.reservedSectors]
	mov dword [edi + tPartitionInfo.rootDir], eax

	; save root directory entry count
	mov eax, 0
	mov ax, word [esi + tFAT16BPB.rootDirectoryEntries]
	mov dword [edi + tPartitionInfo.rootDirEntries], eax

	; calculate the size of the root directory in sectors
	; rootDirSectorCount = rootDirectoryEntries / 16
	shr eax, 4
	mov dword [edi + tPartitionInfo.rootDirSectorCount], eax

	; calculate the size of the root directory in sectors
	; rootDirSize = rootDirSectorCount * 512
	shl eax, 9
	mov dword [edi + tPartitionInfo.rootDirSize], eax

	; get starting LBA address for the data area
	; dataArea = rootDir + (rootDirectoryEntries * 32) / 512
	mov eax, dword [edi + tPartitionInfo.rootDirEntries]
	; shr eax, 4 is a combination of shl eax, 5 to multiply by 32 and shr eax, 9 to divide by 512
	shr eax, 4
	add eax, dword [edi + tPartitionInfo.rootDir]
	mov dword [edi + tPartitionInfo.dataArea], eax

	; calculate total number of clusters in this partition
	; total clusters = (totalsectors - dataarea + 1) / sectorsPerCluster
	mov eax, dword [edi + tPartitionInfo.sectorCount]
	sub eax, dword [edi + tPartitionInfo.dataArea]
	inc eax
	div dword [edi + tPartitionInfo.sectorsPerCluster]
	mov dword [edi + tPartitionInfo.clusterCount], eax

	; set the flag so that we know this partition has been cached in the future
	mov eax, 0
	bts eax, 0
	mov dword [edi + tPartitionInfo.FSFlags], eax

	; if we get here, all went as planned!
	push sectorBufferPtr
	call MemDispose

	mov eax, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FAT16PartitionInfo:
	; Returns space information on the specified partition
	;
	;  input:
	;	Address of this partiton's tPartitionInfo record
	;
	;  output:
	;	EAX - Total clusters
	;	EBX - Clusters free
	;	ECX - Bytes per cluster
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionSlotPtr					dword [ebp + 8]

	; allocate local variables
	sub esp, 4
	%define clustersFree						dword [ebp - 4]


	; get free cluster count
	push partitionSlotPtr
	call FAT16ClusterFreeTotalGet

	; always check for errors, kids
	cmp edx, kErrNone
	jne .Exit
	mov clustersFree, eax


	; get the cached FAT16 info for this partition from the FS-specific area of the partitions list
	mov esi, partitionSlotPtr
	mov eax, dword [esi + tPartitionInfo.clusterCount]

	mov ecx, dword [esi + tPartitionInfo.bytesPerCluster]


	; put the free cluster count into EBX
	mov ebx, clustersFree

	; The only good error... is no error!
	mov edx, kErrNone


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
	;	n/a

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
FAT16ServiceHandler:
	; The FAT16 service routine called by external applications
	;
	;  input:
	;	Command number
	;	Parameter 1
	;	Parameter 2
	;	Parameter 3
	;	Parameter 4
	;	Parameter 5
	;	Parameter 6
	;	Parameter 7
	;
	;  output:
	;	Varies - function specific

	push ebp
	mov ebp, esp

	; define input parameters
	%define command								dword [ebp + 8]
	%define parameter1							dword [ebp + 12]
	%define parameter2							dword [ebp + 16]
	%define parameter3							dword [ebp + 20]
	%define parameter4							dword [ebp + 24]
	%define parameter5							dword [ebp + 28]
	%define parameter6							dword [ebp + 32]
	%define parameter7							dword [ebp + 36]

	; allocate local variables
	sub esp, 8
	%define copyLength							dword [ebp - 4]
	%define pathClone$							dword [ebp - 8]


	cmp command, kDriverInit
	jne .NotInit
		; set this dispatch routine as the handler for all the partition types we handle
		; FAT16 "small" volume
		push 0x04
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; FAT16 "large" volume
		push 0x06
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Windows 95 FAT16 volume
		push 0x0E
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Hidden FAT16 volume
		push 0x16
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		; Hidden Windows 95 FAT16 volume
		push 0x1E
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT16ServiceHandler

		jmp .Exit
	.NotInit:


	; every function after this point expects the partition list address of this
	; partiton element in parameter 1 so we can verify it now before proceeding

	; put the address of this partition's tPartitionInfo record into ESI
	mov esi, parameter1

	; make sure the partition isn't empty/unused
	cmp dword [esi + tPartitionInfo.startingLBA], 0
	jne .PartitionOK
		; If we get here, the partition is invalid. Error!!!
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionOK:

	; see if the FAT16-specific data from this partition has been cached yet and cache it if not
	bt dword [esi + tPartitionInfo.FSFlags], 0
	jc .AlreadyCached
		; load partitionNumber from the cached area
		push esi
		call FAT16PartitionCacheData
	.AlreadyCached:

	cmp command, kDriverPartitionInfo
	jne .NotPartitionInfo
		push parameter1
		call FAT16PartitionInfo
		jmp .Exit
	.NotPartitionInfo:

	; every function after this point expects the file path in parameter 2,
	; so we can help sort things out a bit further here before proceeding

	; make sure the path conforms to FAT16 standards
	push parameter2
	call FAT16PathCanonicalize

	; some of the driver routines which are about to be called will perform destructive operations on the path
	; string, so we create a duplicate for our own purposes so as to not screw up the caller's string area
	push parameter2
	call StringLength

	inc eax
	sub esp, eax
	mov pathClone$, esp
	push eax
	push pathClone$
	push parameter2
	call MemCopy


	cmp command, kDriverItemCount
	jne .NotItemCount
		push parameter3
		push pathClone$
		push parameter1
		call FAT16ItemCount
		jmp .Exit
	.NotItemCount:

	cmp command, kDriverItemDelete
	jne .NotItemDelete
		push pathClone$
		push parameter1
		call FAT16ItemDelete
		jmp .Exit
	.NotItemDelete:

	cmp command, kDriverItemExists
	jne .NotItemExists
		push pathClone$
		push parameter1
		call FAT16ItemExists
		jmp .Exit
	.NotItemExists:

	cmp command, kDriverItemInfoAccessedGet
	jne .NotItemAccessedGet
		push pathClone$
		push parameter1
		call FAT16ItemInfoAccessedGet
		jmp .Exit
	.NotItemAccessedGet:

	cmp command, kDriverItemInfoCreatedGet
	jne .NotItemCreatedGet
		push pathClone$
		push parameter1
		call FAT16ItemInfoCreatedGet
		jmp .Exit
	.NotItemCreatedGet:

	cmp command, kDriverItemInfoModifiedGet
	jne .NotItemModifiedGet
		push pathClone$
		push parameter1
		call FAT16ItemInfoModifiedGet
		jmp .Exit
	.NotItemModifiedGet:

	cmp command, kDriverItemInfoSizeGet
	jne .NotItemSizeGet
		push pathClone$
		push parameter1
		call FAT16ItemInfoSizeGet
		jmp .Exit
	.NotItemSizeGet:

	cmp command, kDriverItemLoad
	jne .NotItemLoad
		push pathClone$
		push parameter1
		call FAT16ItemLoad
		jmp .Exit
	.NotItemLoad:

	cmp command, kDriverItemNew
	jne .NotNewItem
		push parameter3
		push pathClone$
		push parameter1
		call FAT16ItemNew
		jmp .Exit
	.NotNewItem:

	cmp command, kDriverItemStore
	jne .NotItemStore
		push parameter4
		push parameter3
		push pathClone$
		push parameter1
		call FAT16ItemStore
		jmp .Exit
	.NotItemStore:

	.Exit:
	mov esp, ebp
	pop ebp
ret 32





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
	;	Parameter 5
	;	Parameter 6
	;	Parameter 7
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
	%define parameter5							dword [ebp + 28]
	%define parameter6							dword [ebp + 32]
	%define parameter7							dword [ebp + 36]


	; do driver-y things here
	cmp command, kDriverInit
	jne .NotInit
		; init - set FAT32 handler addresses
		push 0x0B
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT32ServiceHandler

		push 0x0C
		push dword [tSystem.listFSHandlers]
		call LM_Internal_ElementAddressGet
		mov dword [esi], FAT32ServiceHandler
	.NotInit:


	mov esp, ebp
	pop ebp
ret 32





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
	call CheckRange
	cmp al, true
	jne .Fail

	push 31
	push 1
	push day
	call CheckRange
	cmp al, true
	jne .Fail

	push 2107
	push 1980
	push year
	call CheckRange
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
	sub esp, 24
	%define nameScratchPtr						12						; 12 byte string
	%define extScratchPtr						24						; 12 byte string


	; get word count
	push .seperatorDot$
	push path$
	call StringWordCount

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

	; pad the extension with spaces to 3 characters
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
	call CheckRange
	cmp al, true
	jne .Fail

	push 59
	push 0
	push minutes
	call CheckRange
	cmp al, true
	jne .Fail

	push 59
	push 0
	push seconds
	call CheckRange
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
