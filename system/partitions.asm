; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; partitions.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 32-bit function listing:
; PartitionEnumerate			Scans the partition tables of all drives in the drive list and loads their data into the partitions list



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



PartitionEnumerate:
	; Scans the partition tables of all drives in the drive list and loads their data into the partitions list
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; storage on the stack for local variables
	sub esp, 4									; address of sector buffer
	sub esp, 4									; number of elements in the drives list
	sub esp, 4									; current element of drive list being processed
	sub esp, 4									; address of current element of drive list being processed
	sub esp, 4									; address of current element of partition list being processed
	sub esp, 4									; offset of the beginning of the current partition's data relative to the start of the sector
	sub esp, 4									; current element of partition list being written to

	; allocate a buffer for the sectors we're going to read, save the address for later
	push 512
	call MemAllocate
	pop dword [ebp - 4]

	; step through the drives list and discover partitions on each hard drive (other drive types are excluded)
	push dword [tSystem.listDrives]
	call LMListGetElementCount
	pop dword [ebp - 8]

	; clear our counter
	mov dword [ebp - 12], 0

	.DriveListLoop:
		; get the address of this drive list element and save it for later
		push dword [ebp - 12]
		push dword [tSystem.listDrives]
		call LMItemGetAddress
		pop esi
		mov [ebp - 16], esi

		; see if this drive is a hard drive
		cmp dword [tDriveInfo.deviceFlags], 1
		jne .NextPartition

		; if we get here, it was a hard drive... let's discover some partitions!

		; load the first sector
		push dword [ebp - 4]
		push 1
		push 0
		push dword [tDriveInfo.ATADeviceNumber]
		push dword [tDriveInfo.ATABasePort]
		call [tDriveInfo.readSector]

		; if partition A exists, add it to the partitions list
		.checkForPartitionA:
		mov esi, [ebp - 4]
		mov edi, tMBR.PartitionOffsetA
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionB
		mov [ebp - 24], edi
		call .BuildPartitionEntry
		
		; if partition B exists, add it to the partitions list
		.checkForPartitionB:
		mov esi, [ebp - 4]
		mov edi, tMBR.PartitionOffsetB
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionC
		mov [ebp - 24], edi
		call .BuildPartitionEntry

		
		; if partition C exists, add it to the partitions list
		.checkForPartitionC:
		mov esi, [ebp - 4]
		mov edi, tMBR.PartitionOffsetC
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .checkForPartitionD
		mov [ebp - 24], edi
		call .BuildPartitionEntry

		
		; if partition D exists, add it to the partitions list
		.checkForPartitionD:
		mov esi, [ebp - 4]
		mov edi, tMBR.PartitionOffsetD
		add esi, edi
		mov ecx, [tPartitionLayout.systemID]
		cmp ecx, 0
		je .NextPartition
		mov [ebp - 24], edi
		call .BuildPartitionEntry


		.NextPartition:
		inc dword [ebp - 12]
		mov eax, dword [ebp - 8]
		mov ebx, dword [ebp - 12]
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
	call LMListFindFirstFreeSlot
	pop eax
	mov [ebp - 28], eax

	; get the starting address of that specific slot into esi and save it for later
	push eax
	push dword [tSystem.listPartitions]
	call LMItemGetAddress
	pop esi
	mov [ebp - 20], esi

	; save base port and device info (from this drive's slot in the drive list) to the slot we're writing in the partition table
	mov esi, [ebp - 16]
	mov ecx, [tDriveInfo.ATABasePort]
	mov edx, [tDriveInfo.ATADeviceNumber]
	mov esi, [ebp - 20]
	mov [tPartitionInfo.ATAbasePort], ecx
	mov [tPartitionInfo.ATAdevice], edx

	; save device flags to this entry in the partition table
	mov esi, [ebp - 16]
	xor ecx, ecx
	mov cl, [tDriveInfo.deviceFlags]
	mov esi, [ebp - 20]
	mov [tPartitionInfo.attributes], ecx

	; save system ID to this entry in the partition table
	mov esi, [ebp - 4]
	add esi, [ebp - 24]
	xor ecx, ecx
	mov cl, [tPartitionLayout.systemID]
	mov esi, [ebp - 20]
	mov [tPartitionInfo.systemID], ecx

	; save starting LBA to this entry in the partition table
	mov esi, [ebp - 4]
	add esi, [ebp - 24]
	mov ecx, [tPartitionLayout.startingLBA]
	mov esi, [ebp - 20]
	mov [tPartitionInfo.startingLBA], ecx

	; save sector count to this entry in the partition table
	mov esi, [ebp - 4]
	add esi, [ebp - 24]
	mov ecx, [tPartitionLayout.sectorCount]
	mov esi, [ebp - 20]
	mov [tPartitionInfo.sectorCount], ecx

	; save drive list number to this entry in the partition table
	mov esi, [ebp - 20]
	mov ecx, [ebp - 12]
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
		pop edi

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
		push dword [ebp - 28]
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
	; first get the address of this drive list element into eax
	mov eax, [ebp - 16]

	; add 24 to point eax to the model string and push it for the StringBuild call
	add eax, 24
	push eax

	; now calculate the size of the partition
	mov esi, [ebp - 20]
	mov eax, [tPartitionInfo.systemID]
	push eax

	push kPrintText$
	push .NoFSDriver$
	call StringBuild

	push kPrintText$
	call PrintIfConfigBits32

	; push the return value on the stack and exit
	; mov dword [ebp + 16], edi
	.FilesystemDetectDone:
ret
.NoFSDriver$									db 'No handler present for type ^p20x^h partition found on ^s', 0x00
