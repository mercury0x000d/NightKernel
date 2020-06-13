; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; disks.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/storageDefines.inc"

%include "include/boolean.inc"
%include "include/errors.inc"
%include "include/globals.inc"
%include "include/lists.inc"
%include "include/memory.inc"
%include "include/numbers.inc"
%include "include/PCI.inc"
%include "include/strings.inc"





bits 32





section .text
SMDiskRead:
	; Reads sectors from the drive specified
	;
	;  input:
	;	Drive list number
	;	Start sector
	;	Sector count
	;	Buffer pointer
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define driveNumber							dword [ebp + 8]
	%define startSector							dword [ebp + 12]
	%define sectorCount							dword [ebp + 16]
	%define bufferPtr							dword [ebp + 20]


	; get the slot address of the drive specified
	push driveNumber
	push dword [tSystem.listPtrDrives]
	call LMElementAddressGet


	; send a driver command to read a sector
	push 0
	push bufferPtr
	push sectorCount
	push startSector
	push driveNumber
	push kDriverRead
	push dword [esi + tDriveInfo.PCIFunction]
	push dword [esi + tDriveInfo.PCIDevice]
	push dword [esi + tDriveInfo.PCIBus]
	call PCIHandlerCommand


	; time to exit
	.LoopDone:
	%undef driveNumber
	%undef startSector
	%undef sectorCount
	%undef bufferPtr
	mov esp, ebp
	pop ebp
ret 16





section .text
SMItemCount:
	; Returns the number of items in the directory specified which have the attribute bits specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string
	;	Attributes to match
	;
	;  output:
	;	EAX - Number of matching items, or zero if error
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define attributes							dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push attributes
	push path$
	push partitionSlotPtr
	push kDriverItemCount
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef attributes
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 12





section .text
SMItemDelete:
	; Deletes the file specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemDelete
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemExists:
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
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemExists
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemInfoAccessedGet:
	; Returns the date of last access for the specified file
	;
	;  input:
	;	Partition number
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
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemInfoAccessedGet
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemInfoCreatedGet:
	; Returns the date and time of creation for the specified file
	;
	;  input:
	;	Partition number
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
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemInfoCreatedGet
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef address
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 12





section .text
SMItemInfoModifiedGet:
	; Returns the date and time of last modification for the specified file
	;
	;  input:
	;	Partition number
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
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemInfoModifiedGet
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemInfoSizeGet:
	; Returns the size in bytes of the file specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string
	;
	;  output:
	;	ECX - File size
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemInfoSizeGet
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemLoad:
	; Returns a buffer containing the file specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string
	;
	;  output:
	;	ESI - Buffer address
	;	EAX - Actual size of item loaded into buffer
	;	EBX - Starting cluster of chain which is loaded into buffer, or zero if root directory
	;	ECX - Buffer size in bytes
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push path$
	push partitionSlotPtr
	push kDriverItemLoad
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
SMItemNew:
	; Creates a new empty file at the path specified
	;
	;  input:
	;	Partition number
	;	Path for new item
	;	Attributes for new item
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define attributes							dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push attributes
	push path$
	push partitionSlotPtr
	push kDriverItemNew
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef attributes
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 12





section .text
SMItemStore:
	; Stores the data at the address specified to the file specified
	;
	;  input:
	;	Partition number
	;	Pointer to file path string
	;	Address of data for file
	;	Length of file data
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define path$								dword [ebp + 12]
	%define address								dword [ebp + 16]
	%define length								dword [ebp + 20]

	; allocate local variables
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push length
	push address
	push path$
	push partitionSlotPtr
	push kDriverItemStore
	call eax


	.Exit:
	%undef partitionNumber
	%undef path$
	%undef address
	%undef length
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 16





section .text
SMPartitionEnumerate:
	; Scans the drives list and discovers partitions on each drive
	;
	;  input:
	;	n/a
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 28
	%define sectorBufferAddr					dword [ebp - 4]		; address of sector buffer
	%define driveListElementCount				dword [ebp - 8]		; number of elements in the drives list
	%define driveListCurrentElement				dword [ebp - 12]	; current element of drive list being processed
	%define driveListCurrentElementAddr			dword [ebp - 16]	; address of current element of drive list being processed
	%define partitionListCurrentElementAddr		dword [ebp - 20]	; address of current element of partition list being processed
	%define offset								dword [ebp - 24]	; offset of the beginning of the current partition's data relative to the start of the sector
	%define partitionListCurrentElement			dword [ebp - 28]	; current element of partition list being written to


	; allocate a buffer for the sectors we're going to read, save the address for later
	call MemAllocate
	mov sectorBufferAddr, eax

	; see if there was an error
	cmp edx, kErrNone
	jne .Exit

	; step through the drives list and discover partitions on each hard drive (other drive types are excluded)
	push dword [tSystem.listPtrDrives]
	call LMElementCountGet
	mov driveListElementCount, ecx

	; clear our counter
	mov driveListCurrentElement, 0

	.DriveListLoop:
		; get the address of this drive list element and save it for later
		push driveListCurrentElement
		push dword [tSystem.listPtrDrives]
		call LMElementAddressGet
		mov driveListCurrentElementAddr, esi

		; see if this drive is a hard drive
		cmp dword [esi + tDriveInfo.deviceFlags], 1
		jne .NextPartition

		; if we get here, it was a hard drive... let's discover some partitions!

		; load the first sector
		push sectorBufferAddr
		push 1
		push 0
		push driveListCurrentElement
		call SMDiskRead

		; if partition A exists, add it to the partitions list
		.checkForPartitionA:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetA
		add esi, edi
		mov ecx, [esi + tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionB
		mov offset, edi
		call .BuildPartitionEntry
		
		; if partition B exists, add it to the partitions list
		.checkForPartitionB:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetB
		add esi, edi
		mov ecx, [esi + tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionC
		mov offset, edi
		call .BuildPartitionEntry

		
		; if partition C exists, add it to the partitions list
		.checkForPartitionC:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetC
		add esi, edi
		mov ecx, [esi + tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionD
		mov offset, edi
		call .BuildPartitionEntry

		
		; if partition D exists, add it to the partitions list
		.checkForPartitionD:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetD
		add esi, edi
		mov ecx, [esi + tPartitionLayout.systemID]
		cmp ecx, 0
		je .NextPartition
		mov offset, edi
		call .BuildPartitionEntry


		.NextPartition:
		inc driveListCurrentElement
		mov eax, driveListElementCount
		mov ebx, driveListCurrentElement
		cmp ebx, eax
		je .LoopDone

	jmp .DriveListLoop


	.BuildPartitionEntry:
		; get first free slot in the partition list
		push dword [tSystem.listPtrPartitions]
		call LMSlotFindFirstFree
		mov partitionListCurrentElement, eax

		; get the starting address of that specific slot into esi and save it for later
		push eax
		push dword [tSystem.listPtrPartitions]
		call LMElementAddressGet
		mov partitionListCurrentElementAddr, esi

		; fill in the partition number
		mov eax, partitionListCurrentElement
		mov [esi + tPartitionInfo.partitionNumber], eax

		; save base port and device info (from this drive's slot in the drive list) to the slot we're writing in the partition table
		mov edi, driveListCurrentElementAddr
		mov eax, [edi + tDriveInfo.ATABasePort]
		mov ebx, [edi + tDriveInfo.ATAControlPort]
		mov ecx, [edi + tDriveInfo.ATADeviceNumber]
		mov [esi + tPartitionInfo.ATABasePort], eax
		mov [esi + tPartitionInfo.ATAControlPort], ebx
		mov [esi + tPartitionInfo.ATADeviceNumber], ecx

		; save PCI info (from this drive's slot in the drive list) to the slot we're writing in the partition table
		mov eax, [edi + tDriveInfo.PCIClass]
		mov ebx, [edi + tDriveInfo.PCISubclass]
		mov [esi + tPartitionInfo.PCIClass], eax
		mov [esi + tPartitionInfo.PCISubclass], ebx

		mov eax, [edi + tDriveInfo.PCIBus]
		mov ebx, [edi + tDriveInfo.PCIDevice]
		mov ecx, [edi + tDriveInfo.PCIFunction]
		mov [esi + tPartitionInfo.PCIBus], eax
		mov [esi + tPartitionInfo.PCIDevice], ebx
		mov [esi + tPartitionInfo.PCIFunction], ecx

		; save device flags to this entry in the partition table
		xor ecx, ecx
		mov cl, [edi + tDriveInfo.deviceFlags]
		mov [esi + tPartitionInfo.attributes], ecx

		; save file system to this entry in the partition table
		mov edi, sectorBufferAddr
		add edi, offset
		xor ecx, ecx
		mov cl, [edi + tPartitionLayout.systemID]
		mov [esi + tPartitionInfo.fileSystem], ecx

		; save starting LBA to this entry in the partition table
		mov ecx, [edi + tPartitionLayout.startingLBA]
		mov [esi + tPartitionInfo.startingLBA], ecx

		; save sector count to this entry in the partition table
		mov ecx, [edi + tPartitionLayout.sectorCount]
		mov [esi + tPartitionInfo.sectorCount], ecx

		; save drive list number to this entry in the partition table
		mov ecx, driveListCurrentElement
		mov [esi + tPartitionInfo.driveListNumber], ecx
	ret


	; time to exit
	.LoopDone:
	mov edx, kErrNone


	.Exit:
	%undef sectorBufferAddr
	%undef driveListElementCount
	%undef driveListCurrentElement
	%undef driveListCurrentElementAddr
	%undef partitionListCurrentElementAddr
	%undef offset
	%undef partitionListCurrentElement
	mov esp, ebp
	pop ebp
ret





section .text
SMPartitionMap:
	; Maps the specified partition to the drive letter specified
	;
	;  input:
	;	Partition number
	;	Drive number (0 = A, 1 = B, etc.)
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define driveNumber							dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define driveSlotAddress					dword [ebp - 4]


	; validate partition number input
	push 255
	push 0
	push partitionNumber
	call RangeCheck
	cmp al, true
	je .PartitionIsInRange
		mov eax, kErrValueTooHigh
		jmp .Exit
	.PartitionIsInRange:

	; validate drive letter input
	push 25
	push 0
	push driveNumber
	call RangeCheck
	cmp al, true
	je .DriveLetterIsInRange
		mov eax, kErrInvalidParameter
		jmp .Exit
	.DriveLetterIsInRange:

	; get the address of this drive list element and save it for later
	push driveNumber
	push dword [tSystem.listPtrDriveLetters]
	call LMElementAddressGet
	mov driveSlotAddress, esi

	; write the partition's slot address into the drive letters table
	mov edi, driveSlotAddress
	mov eax, partitionNumber
	mov [edi], eax

	; exit with no error
	mov eax, kErrNone


	.Exit:
	%undef partitionNumber
	%undef driveNumber
	%undef driveSlotAddress
	mov esp, ebp
	pop ebp
ret 8





section .text
SMPartitionRead:
	; Reads sectors from the partition specified
	;
	;  input:
	;	Partiton list number
	;	Start sector
	;	Sector count
	;	Buffer pointer
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define startSector							dword [ebp + 12]
	%define sectorCount							dword [ebp + 16]
	%define bufferPtr							dword [ebp + 20]


	; get the slot address of the drive specified
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet

	; validate the sectors requested
	mov ebx, dword [esi + tPartitionInfo.sectorCount]
	mov eax, dword [esi + tPartitionInfo.startingLBA]
	add eax, startSector
	cmp eax, ebx
	jae .Fail
	add eax, startSector
	cmp eax, ebx
	jae .Fail

	; send a driver command to read a sector
	push 0
	push bufferPtr
	push sectorCount
	mov eax, startSector
	add eax, dword [esi + tPartitionInfo.startingLBA]
	push eax
	push dword [esi + tPartitionInfo.driveListNumber]
	push kDriverRead
	push dword [esi + tPartitionInfo.PCIFunction]
	push dword [esi + tPartitionInfo.PCIDevice]
	push dword [esi + tPartitionInfo.PCIBus]
	call PCIHandlerCommand
	jmp .Exit

	.Fail:
	mov edx, kErrInvalidPartitionNumber


	.Exit:
	%undef partitionNumber
	%undef startSector
	%undef sectorCount
	%undef bufferPtr
	mov esp, ebp
	pop ebp
ret 16





section .text
SMPartitionWrite:
	; Writes sectors to the partition specified
	;
	;  input:
	;	Partiton list number
	;	Start sector
	;	Sector count
	;	Buffer pointer
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define startSector							dword [ebp + 12]
	%define sectorCount							dword [ebp + 16]
	%define bufferPtr							dword [ebp + 20]


	; get the slot address of the drive specified
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet

	; validate the sectors specified
	mov ebx, dword [esi + tPartitionInfo.sectorCount]
	mov eax, dword [esi + tPartitionInfo.startingLBA]
	add eax, startSector
	cmp eax, ebx
	jae .Fail
	add eax, startSector
	cmp eax, ebx
	jae .Fail

	; send a driver command to read a sector
	push 0
	push bufferPtr
	push sectorCount
	mov eax, startSector
	add eax, dword [esi + tPartitionInfo.startingLBA]
	push eax
	push dword [esi + tPartitionInfo.driveListNumber]
	push kDriverWrite
	push dword [esi + tPartitionInfo.PCIFunction]
	push dword [esi + tPartitionInfo.PCIDevice]
	push dword [esi + tPartitionInfo.PCIBus]
	call PCIHandlerCommand
	jmp .Exit

	.Fail:
	mov edx, kErrInvalidPartitionNumber


	.Exit:
	%undef partitionNumber
	%undef startSector
	%undef sectorCount
	%undef bufferPtr
	mov esp, ebp
	pop ebp
ret 16





section .text
SMPartitionInfo:
	; Returns space information on the specified partition
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
	sub esp, 4
	%define partitionSlotPtr					dword [ebp - 4]


	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPtrPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listPtrFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]

	; make sure we didn't get a null address
	cmp eax, null
	jne .HandlerValid
		; if we get here, throw an error
		mov edx, kErrHandlerNotPresent
		jmp .Exit
	.HandlerValid:

	; farm the work out to the FS handler
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	push partitionSlotPtr
	push kDriverPartitionInfo
	call eax


	.Exit:
	%undef partitionNumber
	%undef partitionSlotPtr
	mov esp, ebp
	pop ebp
ret 4





section .text
SMPathParentGet:
	; Shortens the path given to point to the parent path
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

	; allocate local variables
	sub esp, 4
	%define wordCount							dword [ebp - 4]


	; get the position of the final slash in the path string
	push 92
	push path$
	call StringSearchCharRight

	add eax, path$
	dec eax

	mov byte [eax], 0


	.Exit:
	%undef path$
	%undef wordCount
	mov esp, ebp
	pop ebp
ret 4

section .data
.seperatorSlash$								dw 0092





section .text
SMPathPartitionGet:
	; Returns the partition number based on the path specified
	;
	;  input:
	;	Pointer to file path string
	;
	;  output:
	;	EAX - Partition number
	;	EBX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]

	; allocate local variables
	sub esp, 8
	%define partitionSlotPtr					dword [ebp - 4]
	%define driveLetter							dword [ebp - 8]


	; search for the first occurrance of the colon character (ASCII 58)
	push 58
	push path$
	call StringSearchCharLeft

	cmp eax, 2
	jne .NotDriveLetterBased
		; if it's at position 2, the path is drive letter based (e.g. c:\filename.txt)
		; if we get here, the path is drive letter based

		; get the partition number of this filespec based on the first character of the path string
		push 1
		push path$
		call StringCharGet
		and eax, 0x000000FF

		; see if the drive letter in eax is between 97 and 122; if so, we subtract a little to convert it to a capital letter value
		mov edx, eax
		sub edx, 32
		cmp eax, 97
		jnae .Skip
			mov eax, edx
		.Skip:

		; save eax to driveLetter
		mov driveLetter, eax

		; make sure the ASCII code for this drive letter is between A and Z
		push 90
		push 65
		push driveLetter
		call RangeCheck
		cmp al, true
		je .LetterInRange
			mov ebx, kErrDriveLetterInvalid
			jmp .Fail
		.LetterInRange:

		; translate the drive letter's ASCII code (65 - 90) into an index into the drive letters list (0 - 25)
		sub driveLetter, 65

		; get the partition number from the drive letters list
		push driveLetter
		push dword [tSystem.listPtrDriveLetters]
		call LMElementAddressGet
		mov eax, [esi]

		; If the element in the drive letter list pointed to by the drive letter index contains 0xFFFFFFFF, then that drive letter
		; was never mapped. Throw an error.
		cmp eax, 0xFFFFFFFF
		jne .Success
			mov ebx, kErrDriveLetterInvalid
			jmp .Fail
	.NotDriveLetterBased:

	cmp eax, 3
	jne .NotPartitionBased
		; if it's at position 3, the path is partition based (e.g. 1F:\filename.txt)
		; if we get here, the path is partition based

		; temporarily swap the colon for a null so we can use this string in the following call
		; We'll put it back after we're done. Honest we will!
		mov esi, path$
		mov byte [esi + 2], 0

		; now get the numeric value of this partition
		push path$
		call ConvertStringHexToNumber

		; and finally, restore the colon we so rudely overwrote
		mov esi, path$
		mov byte [esi + 2], 58

		jmp .Success
	.NotPartitionBased:

	; if we get here, the path didn't contain a colon where it was expected
	; this file path has problems!
	mov ebx, kErrPathInvalid

	.Fail:
	mov eax, 0
	jmp .Exit

	.Success:
	mov ebx, kErrNone


	.Exit:
	%undef path$
	%undef partitionSlotPtr
	%undef driveLetter
	mov esp, ebp
	pop ebp
ret 4





section .text
SMPathPartitionStripDrive:
	; Returns the path with the leading drive letter/partition specifier removed
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

	; allocate local variables
	sub esp, 4
	%define colonPosition						dword [ebp - 4]


	; search for the first occurrance of the colon character (ASCII 58)
	push 58
	push path$
	call StringSearchCharLeft
	mov colonPosition, eax

	push path$
	call StringLength

	sub eax, colonPosition

	push eax
	push path$
	call StringTruncateLeft


	.Exit:
	%undef path$
	%undef colonPosition
	mov esp, ebp
	pop ebp
ret 4





section .text
SMPathValidate:
	; Verifies if a path specified is valid per usual DOS rules
	;
	;  input:
	;	Pointer to file path string
	;
	;  output:
	;	EAX - Result
	;		True - Path is valid
	;		False - Path is invalid

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]


	; see if the path contains any invalid characters



	.Exit:
	%undef path$
	mov esp, ebp
	pop ebp
ret 4
