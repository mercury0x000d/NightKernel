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





; tListInfo struct, used to manage lists
struc tListInfo
	.signature									resd 1
	.elementSize								resd 1
	.elementCount								resd 1
	.listSize									resd 1
endstruc





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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; see if the list is valid
	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov esi, 0
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	; see if element is valid
	push elementNum
	push listPtr
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov esi, 0
		mov edx, kErrValueTooHigh
		jmp .Exit
	.ElementValid:

	push elementNum
	push listPtr
	call LM_Internal_ElementAddressGet

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .TestPassed

		; if we get here, the list isn't valid
		mov ecx, 0
		mov edx, kErrInvalidParameter
		jmp .Exit

	.TestPassed:
	push listPtr
	call LM_Internal_ElementCountGet

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define newElementCount						dword [ebp + 12]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push newElementCount
	push listPtr
	call LM_Internal_ElementCountSet

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push elementNum
	push listPtr
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, kErrValueTooHigh
		jmp .Exit
	.ElementValid:

	push elementNum
	push listPtr
	call LM_Internal_ElementDelete

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push elementNum
	push listPtr
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, kErrValueTooHigh
		jmp .Exit
	.ElementValid:

	push elementNum
	push listPtr
	call LM_Internal_ElementDuplicate

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push listPtr
	call LM_Internal_ElementSizeGet
	mov eax, edx

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; check element validity
	mov esi, listPtr
	mov eax, dword [esi + tListInfo.elementCount]

	cmp elementNum, eax
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

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define slotNum								dword [ebp + 12]
	%define newItemPtr							dword [ebp + 16]
	%define newItemSize							dword [ebp + 20]


	push listPtr
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push slotNum
	push listPtr
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, kErrValueTooHigh
		jmp .Exit
	.ElementValid:

	push newItemSize
	push newItemPtr
	push slotNum
	push listPtr
	call LM_Internal_ItemAddAtSlot

	mov edx, kErrNone


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

	; define input parameters
	%define listPtr								dword [ebp + 8]


	push listPtr
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

	; define input parameters
	%define address								dword [ebp + 8]
	%define elementCount						dword [ebp + 12]
	%define elementSize							dword [ebp + 16]

	; allocate local variables
	sub esp, 4
	%define listSize							dword [ebp - 4]


	; calculate the total size of the memory this list will occupy
	mov eax, elementCount
	mov ebx, elementSize
	mov edx, 0x00000000
	mul ebx
	add eax, 16
	mov listSize, eax
	; might want to add code here later to check for edx being non-zero to indicate the list size is over 4 GB


	; get the list ready for writing
	mov esi, address


	; write the data to the start of the list area, starting with the signature
	mov dword [esi + tListInfo.signature], 'list'

	; write the size of each element next
	mov ebx, elementSize
	mov dword [esi + tListInfo.elementSize], ebx

	; write the total number of elements
	mov eax, elementCount
	mov dword [esi + tListInfo.elementCount], eax

	; write total size of list
	mov eax, listSize
	mov dword [esi + tListInfo.listSize], eax


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

	; define input parameters
	%define address								dword [ebp + 8]


	push address
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

	; define input parameters
	%define address								dword [ebp + 8]


	; check list validity
	mov esi, address
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

	; define input parameters
	%define address								dword [ebp + 8]


	push address
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push address
	call LM_Internal_SlotFindFirstFree

	mov edx, kErrNone


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

	; define input parameters
	%define address								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	push address
	call LMListValidate

	cmp edx, true
	je .ListValid
		; if we get here, the list isn't valid
		mov edx, kErrInvalidParameter
		jmp .Exit
	.ListValid:

	push elementNum
	push address
	call LMElementValidate

	cmp edx, true
	je .ElementValid
		; if we get here, the element isn't valid
		mov edx, kErrValueTooHigh
		jmp .Exit
	.ElementValid:

	push elementNum
	push address
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

	; define input parameters
	%define address								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; get the size of each element in this list
	mov esi, address
	mov eax, [esi + tListInfo.elementSize]

	; calculate the new destination address
	mul elementNum
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

	; define input parameters
	%define address								dword [ebp + 8]


	; get the element size
	mov esi, address
	mov ecx, [esi + tListInfo.elementCount]


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

	; define input parameters
	%define address								dword [ebp + 8]
	%define newSlotCount						dword [ebp + 12]


	; set the element size
	mov esi, address
	mov edx, newSlotCount
	mov [esi + tListInfo.elementCount], edx


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

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]

	; allocate local variables
	sub esp, 12
	%define elementSize							dword [ebp - 4]
	%define elementCount						dword [ebp - 8]
	%define loopCounter							dword [ebp - 12]


	; get the element size of this list
	push address
	call LM_Internal_ElementSizeGet
	mov elementSize, eax

	; get the number of elements in this list
	push dword 0
	push address
	call LM_Internal_ElementCountGet

	; save the number of elements for later
	mov elementCount, ecx

	; set up a loop to copy down by one all elements from the one to be deleted to the end
	; Yes, we'll be modifying the contents of a passed parameter here, live and in-place. You got a problem with that? ;)
	dec ecx
	mov ebx, element
	sub ecx, ebx

	.ElementCopyLoop:
		
		; update the loop counter
		mov loopCounter, ecx

		; get the starting address of the destination element
		mov edx, element
		push edx
		mov eax, address
		push eax
		call LM_Internal_ElementAddressGet

		; save the address we got
		push esi

		; get the starting address of the source element
		mov edx, element
		inc edx
		push edx
		push address
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
		inc element

	mov ecx, loopCounter
	loop .ElementCopyLoop

	; update the number of elements in this list
	mov esi, address
	mov eax, dword [esi + tListInfo.elementCount]
	dec eax
	mov dword [esi + tListInfo.elementCount], eax

	; update the list's size field
	mov eax, dword [esi + tListInfo.listSize]
	sub eax, elementSize
	mov dword [esi + tListInfo.listSize], eax


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

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]

	; allocate local variables
	sub esp, 12
	%define elementSize							dword [ebp - 4]
	%define elementCount						dword [ebp - 8]
	%define loopCounter							dword [ebp - 12]


	; get the element size of this list
	push address
	call LM_Internal_ElementSizeGet
	mov elementSize, eax

	; get the number of elements in this list
	push dword 0
	push address
	call LM_Internal_ElementCountGet

	; increment the number of elements and save for later
	inc ecx
	mov elementCount, ecx

	; update the number of elements in this list
	push ecx
	push address
	call LM_Internal_ElementCountSet

	; set up a loop to copy down by one all elements from the end to the one to be duplicated
	mov ecx, elementCount
	dec ecx
	mov ebx, element
	sub ecx, ebx

	.ElementCopyLoop:
		; update our loop counter
		mov loopCounter, ecx

		; get the starting address of the destination element
		dec elementCount
		mov edx, elementCount
		push edx
		push address
		call LM_Internal_ElementAddressGet

		; save this address
		push esi

		; get the starting address of the source element
		mov edx, elementCount
		dec edx
		push edx
		push address
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
	mov esi, address
	mov eax, dword [esi + tListInfo.listSize]
	add eax, elementSize
	mov dword [esi + tListInfo.listSize], eax

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

	; define input parameters
	%define address								dword [ebp + 8]


	; get the element size
	mov esi, address
	mov eax, [esi + tListInfo.elementSize]


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

	; define input parameters
	%define address								dword [ebp + 8]
	%define addSlot								dword [ebp + 12]
	%define newItemAddress						dword [ebp + 16]
	%define newItemSize							dword [ebp + 20]


	mov esi, address
	mov edx, addSlot

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
	mov edi, address
	push edi
	call LM_Internal_ElementSizeGet

	; now compare that to the given size of the new item
	cmp newItemSize, eax
	jle .SizeValid

	; add error handling code here later
	mov ebp, 0xDEAD0004
	jmp $

	.SizeValid:
	; if we get here, the size is ok, so we add it to the list!
	mov esi, newItemAddress
	mov ebx, newItemSize

	; calculate the new destination address
	mov edx, addSlot
	mul edx
	mov edi, address
	add eax, edi
	add eax, 16

	; prep the memory copy
	mov esi, newItemAddress
	mov ebx, newItemSize

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

	; define input parameters
	%define address								dword [ebp + 8]


	; load the list address
	mov esi, address

	; initialize our counter
	mov edx, 0x00000000

	; set up a loop to test all of the elements in this list
	.FindLoop:
		; save the counter
		push edx

		; test this element
		push edx
		push address
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
	mov ecx, [esi + tListInfo.elementCount]
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

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; calculate the element's address in RAM
	mov esi, address
	mov eax, [esi + tListInfo.elementSize]
	mul element
	add eax, esi
	add eax, 16

	; set up a loop to check each byte of this element
	mov ecx, [esi + tListInfo.elementSize]
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
