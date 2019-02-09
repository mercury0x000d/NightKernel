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
; LMItemAddAtSlot				Adds an item to the list specified at the list slot specified
; LMItemAddElement				Adds an item to the list specified at the list slot specified
; LMItemDelete					Deletes the item specified from the list specified
; LMItemGetAddress				Returns the address of the specified element in the list specified
; LMListCompact					Compacts the list specified (eliminates empty slots to make list contiguous)
; LMListDelete					Deletes the list specified
; LMListFindFirstFreeSlot		Finds the first free slot available in the list specified
; LMListGetElementCount			Returns the number of elements in the list specified
; LMListGetElementSize			Returns the size of elements in the list specified
; LMListNew						Creates a new list in memory from the parameters specified
; LMListSearch					Searches the list specified for the element specified
; LMListSlotFreeTest			Tests the element specified in the list specified to see if it is free



bits 32



; tListInfo struct, the header used to manage lists
%define tListInfo.signature						(esi + 00)
%define tListInfo.elementSize					(esi + 04)
%define tListInfo.elementCount					(esi + 08)
%define tListInfo.sizeList						(esi + 12)



LMItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;   list address
	;   slot at which to add element
	;	new item address
	;	new item size
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov edx, [ebp + 12]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0003
	jmp $

	.ListValid:
	; the list passed the data integrity check, so we proceed

	; get the size of each element in this list
	mov edi, dword [ebp + 8]
	push edi
	call LMListGetElementSize
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



LMItemDelete:
	; Deletes the item specified from the list specified
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	
ret



LMItemGetAddress:
	; Returns the address of the specified element in the list specified
	;
	;  input:
	;   list address
	;	element number
	;
	;  output:
	;   element address

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0007
	jmp $

	.ListValid:
	; the list passed the data integrity check, so we proceed

	; now we check that the element requested is within range
	; so first we get the number of elements from the list itself
	mov eax, [tListInfo.elementCount]

	; adjust eax by one since if a list has, say, 10 elements, they would actually be numbered 0 - 9
	dec eax

	; now compare the number of elements to what was requested
	cmp [ebp + 12], eax
	jbe .ElementInRange

	; add error handling code here later
	mov ebp, 0xDEAD0008
	jmp $

	.ElementInRange:
	; if we get here, the element was in range; let's proceed

	; get the size of each element in this list
	mov eax, [tListInfo.elementSize]

	; calculate the new destination address
	mov edx, [ebp + 12]
	mul edx
	add eax, esi
	add eax, 16

	; push the value on the stack and we're done!
	mov dword [ebp + 12], eax

	mov esp, ebp
	pop ebp
ret 4



LMListCompact:
	; Compacts the list specified
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	
ret



LMListDelete:
	; Deletes the list specified
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	
ret



LMListFindFirstFreeSlot:
	; Finds the first free slot available in the list specified
	;
	;  input:
	;   list address
	;
	;  output:
	;   element number of first free slot

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0009
	jmp $

	.ListValid:
	; initialize our counter
	mov edx, 0x00000000

	; set up a loop to test all of the elements in this list
	.FindLoop:
		; save the counter
		push edx

		; test this element
		push edx
		push dword [ebp + 8]
		call LMListSlotFreeTest
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



LMListGetElementCount:
	; Returns the total number of elements in the list specified
	;
	;  input:
	;   list address
	;
	;  output:
	;   number of total element slots in this list

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0006
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed
	; now let's get the element size
	mov edx, [tListInfo.elementCount]

	; fix the stack and exit
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LMListGetElementSize:
	; Returns the size of elements in the list specified
	;
	;  input:
	;   list address
	;
	;  output:
	;   list element size

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0005
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed
	; now let's get the element size
	mov edx, [tListInfo.elementSize]

	; fix the stack and exit
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LMListInit:
	; Creates a new list in memory from the parameters specified at the address specified
	;
	;  input:
	;	address
	;   number of elements
	;	size of each element
	;
	;  output:
	;   n/a

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
	mov dword [tListInfo.sizeList], eax
	add edi, 4

	mov esp, ebp
	pop ebp
ret 12



LMListSearch:
	; Searches the list specified for the element specified
	;
	;  input:
	;   n/a
	;
	;  output:
	;   memory address of list

ret



LMListSlotFreeTest:
	; Tests the element specified in trhe list specified to see if it is free
	;
	;  input:
	;   list address
	;   element number
	;
	;  output:
	;   result
	;		kTrue - element empty
	;		kFalse - element not empty

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]

	; check list validity
	mov eax, dword [esi]
	cmp eax, 0x7473696C
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
