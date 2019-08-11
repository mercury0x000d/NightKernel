; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; disks.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 32





; struct definitions:

; boot sector offsets
%define tMBR.Bootstrap							0x0000
%define tMBR.OUID								0x01B4
%define tMBR.PartitionOffsetA					0x01BE
%define tMBR.PartitionOffsetB					0x01CE
%define tMBR.PartitionOffsetC					0x01DE
%define tMBR.PartitionOffsetD					0x01EE
%define tMBR.Signature							0x01FE





section .text
DiskRead:
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
	push dword [tSystem.listDrives]
	call LMElementAddressGet


	; send a driver command to read a sector
	push 0
	push bufferPtr
	push sectorCount
	push startSector
	push driveNumber
	push kDriverRead
	push dword [tDriveInfo.PCIFunction]
	push dword [tDriveInfo.PCIDevice]
	push dword [tDriveInfo.PCIBus]
	call PCIHandlerCommand


	; time to exit
	.LoopDone:
	mov esp, ebp
	pop ebp
ret





section .text
PartitionEnumerate:
	; Scans the drives list and discovers partitions on each drive
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

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
	push 512
	push dword 1
	call MemAllocate
	mov sectorBufferAddr, eax

	; step through the drives list and discover partitions on each hard drive (other drive types are excluded)
	push dword [tSystem.listDrives]
	call LMElementCountGet
	mov driveListElementCount, ecx

	; clear our counter
	mov driveListCurrentElement, 0

	.DriveListLoop:
		; get the address of this drive list element and save it for later
		push driveListCurrentElement
		push dword [tSystem.listDrives]
		call LMElementAddressGet
		mov driveListCurrentElementAddr, esi

		; see if this drive is a hard drive
		cmp dword [tDriveInfo.deviceFlags], 1
		jne .NextPartition

		; if we get here, it was a hard drive... let's discover some partitions!

		; load the first sector
		push sectorBufferAddr
		push 1
		push 0
		push driveListCurrentElement
		call DiskRead

		; if partition A exists, add it to the partitions list
		.checkForPartitionA:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetA
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionB
		mov offset, edi
		call .BuildPartitionEntry
		
		; if partition B exists, add it to the partitions list
		.checkForPartitionB:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetB
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionC
		mov offset, edi
		call .BuildPartitionEntry

		
		; if partition C exists, add it to the partitions list
		.checkForPartitionC:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetC
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionD
		mov offset, edi
		call .BuildPartitionEntry

		
		; if partition D exists, add it to the partitions list
		.checkForPartitionD:
		mov esi, sectorBufferAddr
		mov edi, tMBR.PartitionOffsetD
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
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

	; time to exit
	.LoopDone:
	mov esp, ebp
	pop ebp
ret

.BuildPartitionEntry:
	; get first free slot in the partition list
	push dword [tSystem.listPartitions]
	call LMSlotFindFirstFree
	mov partitionListCurrentElement, eax

	; get the starting address of that specific slot into esi and save it for later
	push eax
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionListCurrentElementAddr, esi

	; save base port and device info (from this drive's slot in the drive list) to the slot we're writing in the partition table
	mov esi, driveListCurrentElementAddr
	mov eax, [tDriveInfo.ATABasePort]
	mov ebx, [tDriveInfo.ATAControlPort]
	mov ecx, [tDriveInfo.ATADeviceNumber]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.ATABasePort], eax
	mov [tPartitionInfo.ATAControlPort], ebx
	mov [tPartitionInfo.ATADeviceNumber], ecx

	; save PCI info (from this drive's slot in the drive list) to the slot we're writing in the partition table
	mov esi, driveListCurrentElementAddr
	mov eax, [tDriveInfo.PCIClass]
	mov ebx, [tDriveInfo.PCISubclass]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.PCIClass], eax
	mov [tPartitionInfo.PCISubclass], ebx

	mov esi, driveListCurrentElementAddr
	mov eax, [tDriveInfo.PCIBus]
	mov ebx, [tDriveInfo.PCIDevice]
	mov ecx, [tDriveInfo.PCIFunction]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.PCIBus], eax
	mov [tPartitionInfo.PCIDevice], ebx
	mov [tPartitionInfo.PCIFunction], ecx

	; save device flags to this entry in the partition table
	mov esi, driveListCurrentElementAddr
	xor ecx, ecx
	mov cl, [tDriveInfo.deviceFlags]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.attributes], ecx

	; save file system to this entry in the partition table
	mov esi, sectorBufferAddr
	add esi, offset
	xor ecx, ecx
	mov cl, [tPartitionLayout.systemID]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.fileSystem], ecx

	; save starting LBA to this entry in the partition table
	mov esi, sectorBufferAddr
	add esi, offset
	mov ecx, [tPartitionLayout.startingLBA]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.startingLBA], ecx

	; save sector count to this entry in the partition table
	mov esi, sectorBufferAddr
	add esi, offset
	mov ecx, [tPartitionLayout.sectorCount]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.sectorCount], ecx

	; save drive list number to this entry in the partition table
	mov esi, partitionListCurrentElementAddr
	mov ecx, driveListCurrentElement
	mov [tPartitionInfo.driveListNumber], ecx
ret





section .text
PartitionMap:
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
	push dword [tSystem.listDriveLetters]
	call LMElementAddressGet
	mov driveSlotAddress, esi

	; write the partition's slot address into the drive letters table
	mov edi, driveSlotAddress
	mov eax, partitionNumber
	mov [edi], eax

	; exit with no error
	mov eax, kErrNone


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
PartitionRead:
	; Reads sectors from the partition specified
	;
	;  input:
	;	Partiton list number
	;	Start sector
	;	Sector count
	;	Buffer pointer
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define startSector							dword [ebp + 12]
	%define sectorCount							dword [ebp + 16]
	%define bufferPtr							dword [ebp + 20]


	; get the slot address of the drive specified
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; validate the sectors requested
	mov ebx, dword [tPartitionInfo.sectorCount]
	mov eax, dword [tPartitionInfo.startingLBA]
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
	add eax, dword [tPartitionInfo.startingLBA]
	push eax
	push dword [tPartitionInfo.driveListNumber]
	push kDriverRead
	push dword [tPartitionInfo.PCIFunction]
	push dword [tPartitionInfo.PCIDevice]
	push dword [tPartitionInfo.PCIBus]
	call PCIHandlerCommand
	jmp .Exit

	.Fail:
	mov eax, kErrInvalidPartitionNumber


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
PartitionWrite:
	; Writes sectors to the partition specified
	;
	;  input:
	;	Partiton list number
	;	Start sector
	;	Sector count
	;	Buffer pointer
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define partitionNumber						dword [ebp + 8]
	%define startSector							dword [ebp + 12]
	%define sectorCount							dword [ebp + 16]
	%define bufferPtr							dword [ebp + 20]


	; get the slot address of the drive specified
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; validate the sectors specified
	mov ebx, dword [tPartitionInfo.sectorCount]
	mov eax, dword [tPartitionInfo.startingLBA]
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
	add eax, dword [tPartitionInfo.startingLBA]
	push eax
	push dword [tPartitionInfo.driveListNumber]
	push kDriverWrite
	push dword [tPartitionInfo.PCIFunction]
	push dword [tPartitionInfo.PCIDevice]
	push dword [tPartitionInfo.PCIBus]
	call PCIHandlerCommand
	jmp .Exit

	.Fail:
	mov eax, kErrInvalidPartitionNumber


	.Exit:
	mov esp, ebp
	pop ebp
ret 16
