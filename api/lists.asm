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





; external functions
;extern MemCopy

; external variables
;extern kFalse, kTrue





bits 32





section .text
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

	; see if the list is valid
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

	; see if element is valid
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





section .text
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





section .text
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





section .text
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





section .text
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





section .text
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





section .text
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





section .text
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





section .text
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





section .text
LMListInit:
	; Creates a new list from the parameters specified at the address specified
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





section .text
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





section .text
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





section .text
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

	push dword [ebp + 12]
	push dword [ebp + 8]
	call LM_Internal_SlotFreeTest
	pop dword [ebp + 12]

	.Exit:
	mov esp, ebp
	pop ebp
ret 4





section .text
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





section .text
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





section .text
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





section .text
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

	; allocate local variables
	sub esp, 12
	%define elementSize							dword [ebp - 4]
	%define elementCount						dword [ebp - 8]
	%define loopCounter							dword [ebp - 12]

	; get the element size of this list
	push dword [ebp + 8]
	call LM_Internal_ElementSizeGet
	pop elementSize

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	pop ecx
	pop ebx

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
		push elementSize
		push ebx
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
	;	list address
	;	element number to be duplicated
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
	pop elementSize

	; get the number of elements in this list
	push dword 0
	push dword [ebp + 8]
	call LM_Internal_ElementCountGet
	pop ecx
	pop ebx

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
		pop ebx

		; save this address
		push ebx

		; get the starting address of the source element
		mov edx, elementCount
		dec edx
		push edx
		push dword [ebp + 8]
		call LM_Internal_ElementAddressGet
		pop eax
		
		; retrieve the earlier saved address
		pop ebx

		; copy the element data
		push elementSize
		push ebx
		push eax
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





section .text
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





section .text
LM_Internal_ListCompact:

	push ebp
	mov ebp, esp


	
	mov esp, ebp
	pop ebp
ret





section .text
LM_Internal_ListSearch:

	push ebp
	mov ebp, esp



	mov esp, ebp
	pop ebp
ret





section .text
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
		call LM_Internal_SlotFreeTest
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





section .text
LM_Internal_SlotFreeTest:
	; Tests the element specified in the list specified to see if it is free
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
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


	; calculate the element's address in RAM
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
