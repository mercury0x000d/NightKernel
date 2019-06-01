; Night Kernel
; Copyright 2015 - 2019 by Mercury 0x0D
; lists.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; tListInfo struct, the header used to manage lists
%define tListInfo.signature						dword (esi + 00)
%define tListInfo.elementSize					dword (esi + 04)
%define tListInfo.elementCount					dword (esi + 08)
%define tListInfo.listSize						dword (esi + 12)





bits 32





section .text
LMElementAddressGet:
	; Returns the address of the specified element in the list specified
	;
	;  input:
	;	List address
	;	Element number
	;
	;  output:
	;	ESI - Element address
	;	EDX - Result code

	push ebp
	mov ebp, esp


	; see if the list is valid
	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov esi, 0
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	; see if element is valid
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov esi, 0
		mov edx, 0xF002
		jmp .Exit
	.ElementValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementAddressGet
	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementCountGet:
	; Returns the total number of elements in the list specified
	;
	;  input:
	;	List address
	;
	;  output:
	;	ECX - Number of total element slots in this list
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .TestPassed

		; if we get here, the list isn't valid
		mov ecx, 0
		mov edx, 0xF000
		jmp .Exit

	.TestPassed:
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
LMElementCountSet:
	; Sets the total number of elements in the list specified
	;
	;  input:
	;	List address
	;	New number of total element slots in this list
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementCountSet

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementDelete:
	; Deletes the element specified from the list specified
	;
	;  input:
	;	List address
	;	Element number to be deleted
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, 0xF002
		jmp .Exit
	.ElementValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementDelete

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementDuplicate:
	; Duplicates the element specified in the list specified
	;
	;  input:
	;	List address
	;	Element number to be duplicated
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, 0xF002
		jmp .Exit
	.ElementValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementDuplicate

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementSizeGet:
	; Returns the elements size of the list specified
	;
	;  input:
	;	List address
	;
	;  output:
	;	EAX - List element size
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	mov eax, edx

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementValidate:
	; Tests the element specified to be sure it not outside the bounds of the list
	;
	;  input:
	;	List address
	;	Element to check
	;
	;  output:
	;	EDX - Result
	;		true - the element is in range
	;		false - the element is not in range

	push ebp
	mov ebp, esp


	; check element validity
	mov esi, [ebp + 8]
	mov eax, dword [tListInfo.elementCount]

	cmp dword [ebp + 12], eax
	jb .ElementValid

	mov edx, false
	jmp .Done

	.ElementValid:
	mov edx, true


	.Done:
	mov esp, ebp
	pop ebp
ret 8





section .text
LMItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;	List address
	;	Slot at which to add element
	;	New item address
	;	New item size
	;
	;  output:
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 20], 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, 0xF002
		jmp .Exit
	.ElementValid:

	push dword [ebp + 20]
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ItemAddAtSlot

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 16





section .text
LMListCompact:
	; Compacts the list specified (eliminates empty slots to make list contiguous)
	;
	;  input:
	;	List address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LM_Internal_ListCompact


	mov esp, ebp
	pop ebp
ret 4





section .text
LMListInit:
	; Creates a new list from the parameters specified at the address specified
	;
	;  input:
	;	Address
	;	Number of elements
	;	Size of each element
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define listSize							dword [ebp - 4]


	; calculate the total size of the memory this list will occupy
	mov eax, [ebp + 12]
	mov ebx, [ebp + 16]
	mov edx, 0x00000000
	mul ebx
	add eax, 16
	mov listSize, eax
	; might want to add code here later to check for edx being non-zero to indicate the list size is over 4 GB


	; get the list ready for writing
	mov esi, [ebp + 8]


	; write the data to the start of the list area, starting with the signature
	mov dword [tListInfo.signature], 'list'

	; write the size of each element next
	mov ebx, [ebp + 16]
	mov dword [tListInfo.elementSize], ebx

	; write the total number of elements
	mov eax, [ebp + 12]
	mov dword [tListInfo.elementCount], eax

	; write total size of list
	mov eax, listSize
	mov dword [tListInfo.listSize], eax


	mov esp, ebp
	pop ebp
ret 12





section .text
LMListSearch:
	; Searches all elements of the list specified for the data specified
	;
	;  input:
	;	List address
	;
	;  output:
	;	ESI - Memory address of element containing the matching data
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LM_Internal_ListSearch


	mov esp, ebp
	pop ebp
ret 4





section .text
LMListValidate:
	; Tests the list specified for the 'list' signature at the beginning
	;
	;  input:
	;	List address
	;
	;  output:
	;	EDX - Result
	;		true - The list header contains a valid signature
	;		false - The list header does not contain a valid signature

	push ebp
	mov ebp, esp


	; check list validity
	mov esi, [ebp + 8]
	mov eax, dword [esi]

	cmp eax, 'list'
	je .ListValid

	mov edx, false
	jmp .Done

	.ListValid:
	mov edx, true


	.Done:
	mov esp, ebp
	pop ebp
ret 4





section .text
LMSlotFindFirstFree:
	; Finds the first empty element in the list specified
	;
	;  input:
	;	List address
	;
	;  output:
	;	EAX - Element number of first free slot
	;	EDX - Result code

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 8]
	call LM_Internal_SlotFindFirstFree

	mov edx, 0x0000


	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
LMSlotFreeTest:
	; Tests the element specified in the list specified to see if it is free
	;
	;  input:
	;	List address
	;	Element number
	;
	;  output:
	;	EDX - Result
	;		true - Element empty
	;		false - Element not empty

	push ebp
	mov ebp, esp


	push dword [ebp + 8]
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, 0xF000
		jmp .Exit
	.ListValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, 0xF002
		jmp .Exit
	.ElementValid:

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_SlotFreeTest


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LM_Internal_ElementAddressGet:
	; Returns the address of the specified element in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;	Element number
	;
	;  output:
	;	ESI - element address

	push ebp
	mov ebp, esp


	; get the size of each element in this list
	mov esi, [ebp + 8]
	mov eax, [tListInfo.elementSize]

	; calculate the new destination address
	mul dword [ebp + 12]
	lea esi, [eax + esi + 16]


	.Exit:
	mov esp, ebp
	pop ebp
ret 8





section .text
LM_Internal_ElementCountGet:
	; Returns the total number of elements in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;
	;  output:
	;	ECX - Number of total element slots in this list

	push ebp
	mov ebp, esp


	; get the element size
	mov esi, [ebp + 8]
	mov ecx, [tListInfo.elementCount]


	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_ElementCountSet:
	; Sets the total number of elements in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;	New number of total element slots in this list
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; set the element size
	mov esi, [ebp + 8]
	mov edx, [ebp + 12]
	mov [tListInfo.elementCount], edx


	mov esp, ebp
	pop ebp
ret 8





section .text
LM_Internal_ElementDelete:
	; Deletes the element specified from the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;	Element number to be deleted
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 12
	%define elementSize							dword [ebp - 4]
	%define elementCount						dword [ebp - 8]
	%define loopCounter							dword [ebp - 12]


	; get the element size of this list
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	mov elementSize, eax

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet

	; save the number of elements for later
	mov elementCount, ecx

	; set up a loop to copy down by one all elements from the one to be deleted to the end
	dec ecx
	mov ebx, dword [ebp + 12]
	sub ecx, ebx

	.ElementCopyLoop:
		
		; update the loop counter
		mov loopCounter, ecx

		; get the starting address of the destination element
		mov edx, dword [ebp + 12]
		push edx
		mov eax, dword [ebp + 8]
		push eax
		call LM_Internal_ElementAddressGet

		; save the address we got
		push esi

		; get the starting address of the source element
		mov edx, dword [ebp + 12]
		inc edx
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		mov eax, esi

		; retrieve the previous address
		pop esi

		; copy the element data
		push elementSize
		push esi
		push eax
		call MemCopy

		; increment the index
		inc dword [ebp + 12]

	mov ecx, loopCounter
	loop .ElementCopyLoop

	; update the number of elements in this list
	mov esi, dword [ebp + 8]
	mov eax, dword [tListInfo.elementCount]
	dec eax
	mov dword [tListInfo.elementCount], eax

	; update the list's size field
	mov eax, dword [tListInfo.listSize]
	sub eax, elementSize
	mov dword [tListInfo.listSize], eax


	mov esp, ebp
	pop ebp
ret 8





section .text
LM_Internal_ElementDuplicate:
	; Duplicates the element specified in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;	Element number to be duplicated
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 12
	%define elementSize							dword [ebp - 4]
	%define elementCount						dword [ebp - 8]
	%define loopCounter							dword [ebp - 12]


	; get the element size of this list
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	mov elementSize, eax

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet

	; increment the number of elements and save for later
	inc ecx
	mov elementCount, ecx

	; update the number of elements in this list
	push ecx
	push dword [ebp + 8]
	call LM_Internal_ElementCountSet

	; set up a loop to copy down by one all elements from the end to the one to be duplicated
	mov ecx, elementCount
	dec ecx
	mov ebx, dword [ebp + 12]
	sub ecx, ebx

	.ElementCopyLoop:
		; update our loop counter
		mov loopCounter, ecx

		; get the starting address of the destination element
		dec elementCount
		mov edx, elementCount
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet

		; save this address
		push esi

		; get the starting address of the source element
		mov edx, elementCount
		dec edx
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		
		; retrieve the earlier saved address
		pop edi

		; copy the element data
		push elementSize
		push edi
		push esi
		call MemCopy

	mov ecx, loopCounter
	loop .ElementCopyLoop


	; update the list's size field
	mov esi, dword [ebp + 8]
	mov eax, dword [tListInfo.listSize]
	add eax, elementSize
	mov dword [tListInfo.listSize], eax

	mov esp, ebp
	pop ebp
ret 8





section .text
LM_Internal_ElementSizeGet:
	; Returns the elements size of the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;
	;  output:
	;	EAX - List element size

	push ebp
	mov ebp, esp


	; get the element size
	mov esi, [ebp + 8]
	mov eax, [tListInfo.elementSize]


	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_ItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;	List address
	;	Slot at which to add element
	;	New item address
	;	New item size
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	mov esi, [ebp + 8]
	mov edx, [ebp + 12]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 'list'
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0003
	jmp $

	.ListValid:
	; the list passed the data integrity check, so we proceed

	; get the size of each element in this list
	mov edi, dword [ebp + 8]
	push edi
	call LM_Internal_ElementSizeGet

	; now compare that to the given size of the new item
	cmp dword [ebp + 20], eax
	jle .SizeValid

	; add error handling code here later
	mov ebp, 0xDEAD0004
	jmp $

	.SizeValid:
	; if we get here, the size is ok, so we add it to the list!
	mov esi, [ebp + 16]
	mov ebx, [ebp + 20]

	; calculate the new destination address
	mov edx, dword [ebp + 12]
	mul edx
	mov edi, dword [ebp + 8]
	add eax, edi
	add eax, 16

	; prep the memory copy
	mov esi, dword [ebp + 16]
	mov ebx, dword [ebp + 20]

	; copy the memory
	push ebx
	push eax
	push esi
	call MemCopy


	mov esp, ebp
	pop ebp
ret 16





section .text
LM_Internal_ListCompact:
	; Compacts the list specified (eliminates empty slots to make list contiguous)
	;
	;  input:
	;	List address
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	
	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_ListSearch:
	; Searches all elements of the list specified for the data specified
	;
	;  input:
	;	List address
	;
	;  output:
	;	ESI - Memory address of element containing the matching data

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_SlotFindFirstFree:
	; Finds the first empty element in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;
	;  output:
	;	EAX - Element number of first free slot

	push ebp
	mov ebp, esp


	; load the list address
	mov esi, [ebp + 8]

	; initialize our counter
	mov edx, 0x00000000

	; set up a loop to test all of the elements in this list
	.FindLoop:
		; save the counter
		push edx

		; test this element
		push edx
		push dword [ebp + 8]
		call LM_Internal_SlotFreeTest
		mov eax, edx

		; restore the counter
		pop edx

		; check the result
		cmp eax, true
		jne .ElementNotEmpty

		; if we get here, the element was empty
		jmp .Exit

		.ElementNotEmpty:
		inc edx

	; see if we're done here
	mov ecx, [tListInfo.elementCount]
	cmp edx, ecx
	jne .FindLoop


	.Exit:
	mov eax, edx

	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_SlotFreeTest:
	; Tests the element specified in the list specified to see if it is free
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	List address
	;	Element number
	;
	;  output:
	;	EDX - Result
	;		true - element empty
	;		false - element not empty

	push ebp
	mov ebp, esp


	; calculate the element's address in RAM
	mov eax, [tListInfo.elementSize]
	mul edx
	add eax, esi
	add eax, 16

	; set up a loop to check each byte of this element
	mov ecx, [tListInfo.elementSize]
	add eax, ecx
	mov edx, true
	.CheckElement:
		dec eax
		; load a byte from the element into bl
		mov bl, [eax]

		; test bl to see if it's empty
		cmp bl, 0x00

		; decide what to do
		je .ByteWasEmpty

		; if we get here, the byte wasn't empty, so we set a flag and exit this loop
		mov edx, false
		jmp .Exit

		.ByteWasEmpty:
	loop .CheckElement


	.Exit:
	mov esp, ebp
	pop ebp
ret 8
