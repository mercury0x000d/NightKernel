; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; files.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





bits 32





section .text
FMFileDelete:
	; Deletes the file specified
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

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push dword 0
	push pathPtr
	push partitionNumber
	push kDriverFileDelete
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FATFileInfoAccessedGet:
	; Returns the date of last access for the specified file
	;
	;  input:
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
	%define path$								dword [ebp + 8]
	%define address								dword [ebp + 12]

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push dword 0
	push pathPtr
	push partitionNumber
	push kDriverFileInfoAccessedGet
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMFileInfoCreatedGet:
	; Returns the date and time of creation for the specified file
	;
	;  input:
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
	%define path$								dword [ebp + 8]
	%define address								dword [ebp + 12]

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push dword 0
	push pathPtr
	push partitionNumber
	push kDriverFileInfoCreatedGet
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMFileInfoModifiedGet:
	; Returns the date and time of last modification for the specified file
	;
	;  input:
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
	%define path$								dword [ebp + 8]
	%define address								dword [ebp + 12]

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push dword 0
	push pathPtr
	push partitionNumber
	push kDriverFileInfoModifiedGet
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMFileInfoSizeGet:
	; Returns the size in bytes of the file specified
	;
	;  input:
	;	Pointer to file path string
	;
	;  output:
	;	EAX - Error code
	;	ECX - File size

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]
	%define address								dword [ebp + 12]

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push dword 0
	push pathPtr
	push partitionNumber
	push kDriverFileInfoSizeGet
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMFileLoad:
	; Loads the file specified at the address specified
	;
	;  input:
	;	Pointer to file path string
	;	Address at which to load file
	;
	;  output:
	;	EAX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define path$								dword [ebp + 8]
	%define address								dword [ebp + 12]

	; allocate local variables
	sub esp, 16
	%define pathLength							dword [ebp - 4]
	%define pathPtr								dword [ebp - 8]
	%define partitionNumber						dword [ebp - 12]
	%define handlerAddress						dword [ebp - 16]


	; There's a few steps to be done here before we abstract this job out to the appropriate filesystem handler.
	; First, we need to create a duplicate of the path on the stack for our own purposes... mwa ha ha ha!
	push path$
	call StringLength
	mov pathLength, eax

	inc eax
	sub esp, eax
	mov pathPtr, esp
	push eax
	push pathPtr
	push path$
	call MemCopy

	; get the partition number referred to by this path
	push pathPtr
	call FMPathPartitionGet
	mov partitionNumber, eax

	; see if PartitionGetFromPath() returned an error
	mov eax, ebx
	cmp eax, kErrNone
	jne .Exit

	; if the partition is empty/unused, we throw an error
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMSlotFreeTest

	cmp edx, true
	jne .PartitionNotUnused
		; if we get here the partition was unused
		mov eax, kErrInvalidPartitionNumber
		jmp .Exit
	.PartitionNotUnused:

	; get a pointer to the partition's entry in the partitions list
	push partitionNumber
	push dword [tSystem.listPartitions]
	call LMElementAddressGet

	; after the above call, esi will now be pointed to the start of this partition's list entry
	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
	call LMElementAddressGet
	mov eax, dword [esi]
	mov handlerAddress, eax

	; trim the partition specifier or drive letter off the path to simplify things
	push pathPtr
	call FMPathPartitionStripDrive

	; and finally, farm the rest of the work out to the FS handler
	push dword 0
	push address
	push pathPtr
	push partitionNumber
	push kDriverFileLoad
	call handlerAddress


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMPathPartitionGet:
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
	call StringSearchChar

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
		cmovae eax, edx

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
		push dword [tSystem.listDriveLetters]
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
	mov esp, ebp
	pop ebp
ret 4





section .text
FMPathPartitionStripDrive:
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
	call StringSearchChar
	mov colonPosition, eax

	push path$
	call StringLength

	sub eax, colonPosition
	dec eax

	push eax
	push path$
	call StringTruncateLeft


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
FMPathValidate:
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



	mov esp, ebp
	pop ebp
ret 4
