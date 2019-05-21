; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; partitions.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; external functions
;extern DriverSpaceEnd, DriverSpaceStart, LMElementAddressGet, LMElementCountGet, LMSlotFindFirstFree, MemAllocate, MemSearchString
;extern PrintIfConfigBits32, StringTokenHexadecimal

; external variables
;extern kDriverSignature$, tDriveInfo.ATABasePort, tDriveInfo.ATADeviceNumber, tDriveInfo.deviceFlags, tDriveInfo.readSector
;extern tPartitionInfo.ATAbasePort, tPartitionInfo.ATAdevice, tPartitionInfo.attributes, tPartitionInfo.driveListNumber
;extern tPartitionInfo.sectorCount, tPartitionInfo.startingLBA, tPartitionInfo.systemID, tSystem.listDrives, tSystem.listPartitions





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

; partition data as presented on disk
%define tPartitionLayout.bootable				(esi + 00)
%define tPartitionLayout.startingCHS			(esi + 01)
%define tPartitionLayout.systemID				(esi + 04)
%define tPartitionLayout.endingCHS				(esi + 05)
%define tPartitionLayout.startingLBA			(esi + 08)
%define tPartitionLayout.sectorCount			(esi + 12)





section .text
PartitionEnumerate:
	; Scans the partition tables of all drives in the drive list and loads their data into the partitions list
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
		push dword [tDriveInfo.ATADeviceNumber]
		push dword [tDriveInfo.ATABasePort]
		call [tDriveInfo.readSector]

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
	mov ecx, [tDriveInfo.ATABasePort]
	mov edx, [tDriveInfo.ATADeviceNumber]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.ATAbasePort], ecx
	mov [tPartitionInfo.ATAdevice], edx

	; save device flags to this entry in the partition table
	mov esi, driveListCurrentElementAddr
	xor ecx, ecx
	mov cl, [tDriveInfo.deviceFlags]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.attributes], ecx

	; save system ID to this entry in the partition table
	mov esi, sectorBufferAddr
	add esi, offset
	xor ecx, ecx
	mov cl, [tPartitionLayout.systemID]
	mov esi, partitionListCurrentElementAddr
	mov [tPartitionInfo.systemID], ecx

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



	; this loop checks all filesystem drivers to find one that handles the filesystem type we need
	mov esi, DriverSpaceStart

	.FindAppropriateFSDriverLoop:
		; preserve the search address
		push esi

		; search for the signature of the first driver
		push kDriverSignature$
		push dword 16
		push esi
		call MemSearchString
		mov edi, eax

		; restore search address
		pop esi

		; test the result
		cmp edi, 0
		jne .CheckFSDriver
		
		; if we get here, we got a zero back... so no driver was found
		jmp .NextDriverIteration

		.CheckFSDriver:
		; well, ok, we found some random driver... let's see if it can handle this device
		
		; get edi pointing to the driver flags and see if we have a file system driver
		add edi, 16
		mov eax, [edi]
		and eax, 01000000000000000000000000000000b
		cmp eax, 01000000000000000000000000000000b
		je .DriverIsFS

		; if we get here, it's not a file system driver
		jmp .NextDriverIteration

		.DriverIsFS:
		; it's a file system driver! now check if it's for the FS type of this partition
		add edi, 4
		mov eax, [edi]
		mov ecx, [tPartitionInfo.systemID]
		cmp eax, ecx
		je .FSTypeMatch

		; if we get here, the file system type that this driver handles does not match that of this partition
		jmp .NextDriverIteration
		
		.FSTypeMatch:
		; this driver should do the trick!
		; point edi to the start of the driver's init code
		add edi, 12

		; push the partition list index, run the driver, then return
		push partitionListCurrentElement
		call edi
		pop eax
		jmp .FilesystemDetectDone

		.NextDriverIteration:
		; increment our search address and go back to scan again for another driver
		inc esi

		; exit if we're at the end of driver space
		cmp esi, DriverSpaceEnd
		je .DriverScanDone

	jmp .FindAppropriateFSDriverLoop

	.DriverScanDone:
	; if we get here, we found no drivers to handle the file system type of this partition...
	; so to be friendly, let's print a message saying so, if ConfigBits allows us to be verbose, that is :)

	push dword 2
	mov esi, partitionListCurrentElementAddr
	mov eax, [tPartitionInfo.systemID]
	push eax
	push .scratch$
	push .NoFSDriver$
	call StringTokenHexadecimal


	push .scratch$
	call PrintIfConfigBits32

	; push the return value on the stack and exit
	; mov dword [ebp + 16], edi
	.FilesystemDetectDone:
ret

section .data
.NoFSDriver$									db 'No handler present for type 0x^ partition', 0x00

section .bss
.scratch$										resb 80
