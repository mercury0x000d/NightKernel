; Night Kernel;
; Copyright 1995 - 2019 by mercury0x0d
; FAT12.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 32-bit function listing:
; FAT12FileCreate				Creates a new file at the path specified
; FAT12FileDelete				Deletes the file specified
; FAT12FileInfoGet				Returns info data for the file specified
; FAT12FileInfoSet				Writes info data for the file specified
; FAT12FileRead					Reads data from the file structure on disk to a memory buffer
; FAT12FileSizeGet				Gets the size of the file specified
; FAT12FileSizeSet				Sets the size of the file specified
; FAT12FileWrite				Writes data from memory to the file structure on disk



bits 32



FSType01DriverHeader:
.signature$										db 'N', 0x01, 'g', 0x09, 'h', 0x09, 't', 0x05, 'D', 0x02, 'r', 0x00, 'v', 0x01, 'r', 0x05
.driverFlags									dd 01000000000000000000000000000000b

; fields specific to this type of driver
.FSType											dd 0x00000001
.ReadFunctionPointer							dd 0x00000000
.WriteFunctionPointer							dd 0x00000000



FSType01Init:
	; Performs any necessary setup of the driver
	;
	;  input:
	;	partition list number
	;
	;  output:
	;	driver response

	push ebp
	mov ebp, esp

	; local vars
	sub esp, 4									; partition index
	sub esp, 4									; partition index address

	; get the partition index off the stack and save it for later
	mov esi, [ebp + 8]
	mov [ebp - 4], esi

	; get the address of this partition index
	push esi
	push dword [tSystem.listPartitions]
	call LMElementAddressGet
	pop dword [ebp - 8]
	; ignore error code
	pop ecx


	; announce ourselves! (if appropriate... we don't wanna be that one guy at the dinner table yelling over everyone's otherwise pleasant meal)

	; set address of the thing to print info on what we found, 
	mov eax, [tSystem.configBits]
	and eax, 000000000000000000000000000000010b
	cmp eax, 000000000000000000000000000000010b
	jne .NoPrint

		; we got here, so it's print time!
		; first get the address of this drive list element into eax
		mov esi, [ebp - 8]
		mov eax, [tPartitionInfo.driveListNumber]
		push eax
		push dword [tSystem.listDrives]
		call LMElementAddressGet
		pop eax
		; ignore error code
		pop ecx

		; add 24 to point eax to the model string and push it for the StringBuild call
		add eax, 24
		push eax

		; now calculate the size of the partition
		mov esi, [ebp - 8]
		mov eax, [tPartitionInfo.sectorCount]
		shr eax, 1
		push eax

		push kPrintText$
		push .FAT12Found$
		call StringBuild

		push kPrintText$
		call PrintIfConfigBits32
	.NoPrint:




	; fill in handler addresses
	;mov esi, [ebp - 20]
	;mov [tPartitionInfo.fileLoad], FAT12FileLoad
	;mov [tPartitionInfo.fileSave], FAT12FileSave

	; exit with return status
	mov eax, 0x00000000
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret
.FAT12Found$									db '^d KiB FAT12 (type 0x01) partition found on ^s', 0x00










; get info from the first sector
call .LoadBPB
call .LoadExtendedBootRecord

.LoadBPB:
	; load information from the BIOS Parameter Block to this partition entry
ret

.LoadExtendedBootRecord:
	; load information from the Extended Boot Record to this partition entry

ret



FAT12FileCreate:
	; Creates a new file at the path specified
	;
	;  input:
	;   filepath string for the new file
	;	initial length of file
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileDelete:
	; Deletes the file specified
	;
	;  input:
	;   filepath string to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileInfoGet:
	; Returns info data for the file specified
	;
	;  input:
	;	address of file data in memory
	;	length of file data in memory
	;   filepath string to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileInfoSet:
	; Writes info data for the file specified
	;
	;  input:
	;	address of file data in memory
	;	length of file data in memory
	;   filepath string to which data will be written
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileRead:
	; Reads data from the file structure on disk to a memory buffer
	;
	;  input:
	;   path string for file from which data will be read
	;	offset from beginning of file from which to start reading data
	;	length of file data to be retrieved
	;	address to which file data will be loaded in memory
	;
	;  output:
	;   file data is copied into buffer

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileSizeGet:
	; Gets the size of the file specified
	;
	;  input:
	;   path string of file
	;
	;  output:
	;	length of file

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileSizeSet:
	; Sets the size of the file specified
	; Note: If necessary, additional clusters will be allocated or disposed of to meet the size requested
	;
	;  input:
	;   path string of file
	;	new length of file
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret



FAT12FileWrite:
	; Writes data from memory to the file structure on disk
	;
	;  input:
	;	address of data in memory
	;	length of data to be written
	;   path string for file to which data will be written
	;	offset from beginning of file at which to start writing data
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp

ret
