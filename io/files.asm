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
FMItemDelete:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemDelete
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMItemInfoAccessedGet:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemInfoAccessedGet
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMItemInfoCreatedGet:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemInfoCreatedGet
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FMItemInfoModifiedGet:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemInfoModifiedGet
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMItemInfoSizeGet:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemInfoSizeGet
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMItemLoad:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemLoad
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
FMItemNew:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push attributes
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemNew
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 12





section .text
FMItemStore:
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
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	mov partitionSlotPtr, esi

	; Now we use the filesystem type to get the address of the handler for this type of FS
	push dword [esi + tPartitionInfo.fileSystem]
	push dword [tSystem.listFSHandlers]
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
	push length
	push address
	push path$
	push partitionSlotPtr
	push partitionNumber
	push kDriverItemStore
	call eax


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
FMPathParentGet:
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
	mov esp, ebp
	pop ebp
ret 4

section .data
.seperatorSlash$								dw 0092





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
	call StringSearchCharLeft
	mov colonPosition, eax

	push path$
	call StringLength

	sub eax, colonPosition

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
