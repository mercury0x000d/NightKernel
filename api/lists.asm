; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; lists.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 32-bit function listing:
; public functions (the only functions to be called from outside the List Manager routines; list validation is performed)
; LMElementAddressGet						Returns the address of the specified element in the list specified
; LMElementCountGet							Returns the number of elements in the list specified
; LMElementCountSet							Sets the total number of elements in the list specified
; LMElementDelete							Deletes the element at the slot number specified from the list specified
; LMElementDuplicate						Duplicates the element at the slot number specified in the list specified
; LMElementSizeGet							Returns the size of elements in the list specified
; LMElementValidate							Tests the element specified to be sure it not outside the bounds of the list
; LMItemAddAtSlot							Adds an item to the list specified at the list slot specified
; LMListCompact								Compacts the list specified (eliminates empty slots to make list contiguous)
; LMListInit								Creates a new list in memory from the parameters specified
; LMListSearch								Searches the list specified for the element specified
; LMListValidate							Tests the list specified for the 'list' signature at the beginning
; LMSlotFindFirstFree						Finds the first free slot available in the list specified
; LMSlotFreeTest							Tests the element specified in the list specified to see if it is free

; internal functions (to be called from inside the List Manager only; they do no list validating)
; LM_Internal_ElementAddressGet				Returns the address of the specified element in the list specified
; LM_Internal_ElementCountGet				Returns the number of elements in the list specified
; LM_Internal_ElementCountSet				Sets the total number of elements in the list specified
; LM_Internal_ElementDelete					Deletes the element at the slot number specified from the list specified
; LM_Internal_ElementDuplicate				Duplicates the element at the slot number specified in the list specified
; LM_Internal_ElementSizeGet				Returns the size of elements in the list specified
; LM_Internal_ItemAddAtSlot					Adds an item to the list specified at the list slot specified
; LM_Internal_ListCompact					Compacts the list specified (eliminates empty slots to make list contiguous)
; LM_Internal_ListSearch					Searches the list specified for the element specified
; LM_Internal_SlotFindFirstFree				Finds the first free slot available in the list specified
; LM_Internal_SlotFreeTest					Tests the element specified in the list specified to see if it is free



; tListInfo struct, the header used to manage lists
%define tListInfo.signature						(esi + 00)
%define tListInfo.elementSize					(esi + 04)
%define tListInfo.elementCount					(esi + 08)
%define tListInfo.listSize						(esi + 12)



bits 32



LMElementAddressGet:
	; Returns the address of the specified element in the list specified
	;
	;  input:
	;	list address
	;	element number
	;
	;  output:
	;	element address
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate
	pop eax
	cmp eax, [kTrue]
	je .ElementValid

		; if we get here, the element isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF002
		jmp .Exit

	.ElementValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementAddressGet
	pop dword [ebp + 8]
	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret



LMElementCountGet:
	; Returns the total number of elements in the list specified
	;
	;  input:
	;	list address
	;	dummy value
	;
	;  output:
	;	number of total element slots in this list
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .TestPassed

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.TestPassed:
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	pop dword [ebp + 8]
	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret



LMElementCountSet:
	; Sets the total number of elements in the list specified
	;
	;  input:
	;	list address
	;	new number of total element slots in this list
	;
	;  output:
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementCountSet
	
	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret 4



LMElementDelete:
	; Deletes the element specified from the list specified
	;
	;  input:
	;	list address
	;	element number to be deleted
	;
	;  output:
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate
	pop eax
	cmp eax, [kTrue]
	je .ElementValid

		; if we get here, the element isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF002
		jmp .Exit

	.ElementValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementDelete

	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret 4



LMElementDuplicate:
	; Duplicates the element specified in the list specified
	;
	;  input:
	;	list address
	;	element number to be duplicated
	;
	;  output:
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate
	pop eax
	cmp eax, [kTrue]
	je .ElementValid

		; if we get here, the element isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF002
		jmp .Exit

	.ElementValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ElementDuplicate

	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret 4



LMElementSizeGet:
	; Returns the elements size of the list specified
	;
	;  input:
	;	list address
	;	dummy value
	;
	;  output:
	;	list element size
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	pop dword [ebp + 8]

	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret



LMElementValidate:
	; Tests the element specified to be sure it not outside the bounds of the list
	;
	;  input:
	;	list address
	;	element to check
	;
	;  output:
	;	result
	;		kTrue - the element is in range
	;		kFalse - the element is not in range

	push ebp
	mov ebp, esp

	; check element validity
	mov esi, [ebp + 8]
	mov eax, dword [tListInfo.elementCount]
	cmp dword [ebp + 12], eax
	jb .ElementValid

	mov eax, [kFalse]

	.ElementValid:
	mov eax, [kTrue]

	mov dword [ebp + 12], eax

	mov esp, ebp
	pop ebp
ret 4



LMItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;	list address
	;	slot at which to add element
	;	new item address
	;	new item size
	;
	;  output:
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 20], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LMElementValidate
	pop eax
	cmp eax, [kTrue]
	je .ElementValid

		; if we get here, the element isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 20], 0xF002
		jmp .Exit

	.ElementValid:
	push dword [ebp + 20]
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_ItemAddAtSlot

	mov dword [ebp + 20], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret 12



LMListCompact:
	; Compacts the list specified (eliminates empty slots to make list contiguous)
	;
	;  input:
	;	list address
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



LMListInit:
	; Creates a new list in memory from the parameters specified at the address specified
	;
	;  input:
	;	address
	;	number of elements
	;	size of each element
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov eax, [ebp + 12]
	mov ebx, [ebp + 16]

	; write the data to the start of the list area, starting with the signature
	mov dword [tListInfo.signature], 'list'
	add edi, 4

	; write the size of each element next
	mov dword [tListInfo.elementSize], ebx
	add edi, 4

	; write the total number of elements
	mov dword [tListInfo.elementCount], eax

	; calculate size of memory block needed to hold the actual list data into eax (may overwrite edx)
	; might want to add code here to check for edx being non-zero to indicate the list size is over 4 GB
	mul ebx

	; add bytes for the control block on the beginning of the list data
	add eax, 16

	; total size of list gets written first after being retrieved from the stack
	mov dword [tListInfo.listSize], eax
	add edi, 4

	mov esp, ebp
	pop ebp
ret 12



LMListSearch:
	; Searches all elements of the list specified for the data specified
	;
	;  input:
	;	list address
	;
	;  output:
	;	memory address of list

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LM_Internal_ListSearch
	pop dword [ebp + 8]

	mov esp, ebp
	pop ebp
ret



LMListValidate:
	; Tests the list specified for the 'list' signature at the beginning
	;
	;  input:
	;	list address
	;
	;  output:
	;	result
	;		kTrue - the regions are identical
	;		kFalse - the regions are different

	push ebp
	mov ebp, esp

	; check list validity
	mov esi, [ebp + 8]
	mov eax, dword [esi]
	cmp eax, 'list'
	je .ListValid

	mov eax, [kFalse]

	.ListValid:
	mov eax, [kTrue]

	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret



LMSlotFindFirstFree:
	; Finds the first empty element in the list specified
	;
	;  input:
	;	list address
	;	dummy value
	;
	;  output:
	;	element number of first free slot
	;	result code

	push ebp
	mov ebp, esp

	push dword [ebp + 8]
	call LMListValidate
	pop eax
	cmp eax, [kTrue]
	je .ListValid

		; if we get here, the list isn't valid
		mov dword [ebp + 8], 0
		mov dword [ebp + 12], 0xF000
		jmp .Exit

	.ListValid:
	push dword [ebp + 8]
	call LM_Internal_SlotFindFirstFree
	pop dword [ebp + 8]

	mov dword [ebp + 12], 0x0000

	.Exit:
	mov esp, ebp
	pop ebp
ret



LMSlotFreeTest:
	; Tests the element specified in the list specified to see if it is free
	;
	;  input:
	;	list address
	;	element number
	;
	;  output:
	;	result
	;		kTrue - element empty
	;		kFalse - element not empty

	push ebp
	mov ebp, esp

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_SlotFreeTest
	pop dword [ebp + 12]

	mov esp, ebp
	pop ebp
ret 4



LM_Internal_ElementAddressGet:
	; Returns the address of the specified element in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;	element number
	;
	;  output:
	;	element address

	push ebp
	mov ebp, esp

	; check that the element requested is within range
	; so first we get the number of elements from the list itself
	mov esi, [ebp + 8]
	mov eax, [tListInfo.elementCount]

	; adjust eax by one since if a list has, say, 10 elements, they would actually be numbered 0 - 9
	dec eax

	; get the size of each element in this list
	mov eax, [tListInfo.elementSize]

	; calculate the new destination address
	mov edx, [ebp + 12]
	mul edx
	add eax, esi
	add eax, 16

	; push the value on the stack and we're done!
	mov dword [ebp + 12], eax

	.Exit:
	mov esp, ebp
	pop ebp
ret 4



LM_Internal_ElementCountGet:
	; Returns the total number of elements in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;
	;  output:
	;	number of total element slots in this list

	push ebp
	mov ebp, esp

	; get the element size
	mov esi, [ebp + 8]
	mov edx, [tListInfo.elementCount]

	; fix the stack and exit
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LM_Internal_ElementCountSet:
	; Sets the total number of elements in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;	new number of total element slots in this list
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



LM_Internal_ElementDelete:
	; Deletes the element specified from the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;	element number to be deleted
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; local variables
	sub esp, 4									; element size
	sub esp, 4									; element count
	sub esp, 4									; loop counter

	; get the element size of this list
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	pop dword [ebp - 4]

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	pop ecx
	pop ebx

	; save the number of elements for later
	mov dword [ebp - 8], ecx

	; set up a loop to copy down by one all elements from the one to be deleted to the end
	dec ecx
	mov ebx, dword [ebp + 12]
	sub ecx, ebx

	.ElementCopyLoop:
		
		; update the loop counter
		mov dword [ebp - 12], ecx

		; get the starting address of the destination element
		mov edx, dword [ebp + 12]
		push edx
		mov eax, dword [ebp + 8]
		push eax
		call LM_Internal_ElementAddressGet
		pop ebx

		; save the address we got
		push ebx

		; get the starting address of the source element
		mov edx, dword [ebp + 12]
		inc edx
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		pop eax

		; retrieve the previous address
		pop ebx

		; copy the element data
		push dword [ebp - 4]
		push ebx
		push eax
		call MemCopy

		; increment the index
		inc dword [ebp + 12]

	mov ecx, dword [ebp - 12]
	loop .ElementCopyLoop

	; update the number of elements in this list
	mov esi, dword [ebp + 8]
	mov eax, dword [tListInfo.elementCount]
	dec eax
	mov dword [tListInfo.elementCount], eax

	; update the list's size field
	mov eax, dword [tListInfo.listSize]
	sub eax, dword [ebp - 4]
	mov dword [tListInfo.listSize], eax

	mov esp, ebp
	pop ebp
ret 8



LM_Internal_ElementDuplicate:
	; Duplicates the element specified in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;	element number to be duplicated
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; local variables
	sub esp, 4									; element size
	sub esp, 4									; element count
	sub esp, 4									; loop counter

	; get the element size of this list
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	pop dword [ebp - 4]

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	pop ecx
	pop ebx

	; increment the number of elements and save for later
	inc ecx
	mov dword [ebp - 8], ecx

	; update the number of elements in this list
	push ecx
	push dword [ebp + 8]
	call LM_Internal_ElementCountSet

	; set up a loop to copy down by one all elements from the end to the one to be duplicated
	mov ecx, dword [ebp - 8]
	dec ecx
	mov ebx, dword [ebp + 12]
	sub ecx, ebx

	.ElementCopyLoop:
		; update our loop counter
		mov dword [ebp - 12], ecx

		; get the starting address of the destination element
		dec dword [ebp - 8]
		mov edx, dword [ebp - 8]
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		pop ebx

		; save this address
		push ebx

		; get the starting address of the source element
		mov edx, dword [ebp - 8]
		dec edx
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		pop eax
		
		; retrieve the earlier saved address
		pop ebx

		; copy the element data
		push dword [ebp - 4]
		push ebx
		push eax
		call MemCopy

	mov ecx, dword [ebp - 12]
	loop .ElementCopyLoop


	; update the list's size field
	mov esi, dword [ebp + 8]
	mov eax, dword [tListInfo.listSize]
	add eax, dword [ebp - 4]
	mov dword [tListInfo.listSize], eax

	mov esp, ebp
	pop ebp
ret 8



LM_Internal_ElementSizeGet:
	; Returns the elements size of the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;
	;  output:
	;	list element size

	push ebp
	mov ebp, esp

	; get the element size
	mov esi, [ebp + 8]
	mov edx, [tListInfo.elementSize]

	; fix the stack and exit
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LM_Internal_ItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;	list address
	;	slot at which to add element
	;	new item address
	;	new item size
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
	pop eax

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



LM_Internal_ListCompact:

	push ebp
	mov ebp, esp


	
	mov esp, ebp
	pop ebp
ret



LM_Internal_ListSearch:

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret



LM_Internal_SlotFindFirstFree:
	; Finds the first empty element in the list specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
	;
	;  input:
	;	list address
	;
	;  output:
	;	element number of first free slot

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
		call LMSlotFreeTest
		pop eax

		; restore the counter
		pop edx

		; check the result
		cmp eax, [kTrue]
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
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LM_Internal_SlotFreeTest:

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 'list'
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0001
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed

	; first we check that the element being tested is within the range of the list
	; do to this, first we get the number of elements in this list
	mov ecx, [tListInfo.elementCount]

	; see if it's in range
	dec ecx
	mov edx, [ebp + 12]
	cmp edx, ecx
	jle .ElementValid

	; add error handling code here later
	mov ebp, 0xDEAD0002
	jmp $

	.ElementValid:
	; if we get here, the element is within range, so we caclulate the element's address in RAM
	mov eax, [tListInfo.elementSize]
	mul edx
	add eax, esi
	add eax, 16

	; set up a loop to check each byte of this element
	mov ecx, [tListInfo.elementSize]
	add eax, ecx
	mov edx, [kTrue]
	.CheckElement:
		dec eax
		; load a byte from the element into bl
		mov bl, [eax]

		; test bl to see if it's empty
		cmp bl, 0x00

		; decide what to do
		je .ByteWasEmpty

		; if we get here, the byte wasn't empty, so we set a flag and exit this loop
		mov edx, [kFalse]
		jmp .Exit

		.ByteWasEmpty:
	loop .CheckElement

	; and exit
	.Exit:
	mov dword [ebp + 12], edx

	mov esp, ebp
	pop ebp
ret 4
