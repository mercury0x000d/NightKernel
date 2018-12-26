; Night Kernel
; Copyright 1995 - 2018 by mercury0x0d
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
; LMItemDelete					Deletes the item specified from the list specified
; LMItemGetAddress				Returns the address of the specified element in the list specified
; LMListCompact					Compacts the list specified
; LMListDelete					Deletes the list specified
; LMListFindFirstFreeSlot		Finds the first free slot available in the list specified
; LMListGetElementCount			Returns the number of elements in the list specified
; LMListGetElementSize			Returns the size of elements in the list specified
; LMListNew						Creates a new list in memory from the parameters specified
; LMListSearch					Searches the list specified for the element specified
; LMListSlotFreeTest			Tests the element specified in trhe list specified to see if it is free



bits 32



LMItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	;
	;  input:
	;   table address
	;   element at which to add element
	;	new item address
	;	new item size
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov edi, [ebp + 8]
	mov edx, [ebp + 12]
	mov esi, [ebp + 16]
	mov ebx, [ebp + 20]

	; check list validity
	mov eax, dword [edi]
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
	; calculate the new destination address
	mov edx, dword [ebp + 12]
	mul edx
	mov edi, dword [ebp + 8]
	add eax, edi
	add eax, 20

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

	mov edi, [ebp + 8]
	mov edx, [ebp + 12]

	; check list validity
	mov eax, dword [edi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0007
	jmp $

	.ListValid:
	; the list passed the data integrity check, so we proceed

	; now we check that the element requested is within range
	; so first we get the number of elements from the list itself
	mov edi, [ebp + 8]
	push edi
	call LMListGetElementCount
	pop eax

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
	mov edi, [ebp + 8]
	push edi
	call LMListGetElementSize
	pop eax

	; calculate the new destination address
	mov edx, [ebp + 12]
	mul edx
	mov edi, [ebp + 8]
	add eax, edi
	add eax, 20

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

	mov edi, [ebp + 8]

	; save the address
	push edi

	; get the number of elements in this list
	push edi
	call LMListGetElementCount
	pop ecx

	; restore the address
	pop edi

	; initialize our counter
	mov esi, 0x00000000

	; set up a loop to test all of the elements in this list
	.FindLoop:
		; save the important stuff
		push ecx
		push esi
		push edi

		; test this element
		push esi
		push edi
		call LMListSlotFreeTest
		pop eax

		; restore the important stuff
		pop edi
		pop esi
		pop ecx

		; check the result
		cmp eax, [kTrue]
		jne .ElementNotEmpty

		; if we get here, the element was empty
		jmp .Exit

		.ElementNotEmpty:
		inc esi

	cmp esi, ecx
	jne .FindLoop

	.Exit:
	; set the stack and exit
	mov dword [ebp + 8], esi

	mov esp, ebp
	pop ebp
ret



LMListGetElementCount:
	; Returns the number of elements in the list specified
	;
	;  input:
	;   list address
	;
	;  output:
	;   number of total element slots in this list

	push ebp
	mov ebp, esp

	mov edi, [ebp + 8]

	; check list validity
	mov eax, dword [edi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0006
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed
	; now let's get the element size
	add edi, 8
	mov edx, [edi]

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

	mov edi, [ebp + 8]

	; check list validity
	mov eax, dword [edi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0005
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed
	; now let's get the element size
	add edi, 16
	mov edx, [edi]

	; fix the stack and exit
	mov dword [ebp + 8], edx

	mov esp, ebp
	pop ebp
ret



LMListNew:
	; Creates a new list in memory from the parameters specified
	;
	;  input:
	;   number of elements
	;	size of each element
	;
	;  output:
	;   memory address of list

	push ebp
	mov ebp, esp

	mov eax, [ebp + 8]
	mov ebx, [ebp + 12]

	; save eax and ebx for later
	push ebx
	push eax

	; calculate size of memory block needed to hold the actual list data into eax (may overwrite edx)
	; might want to add code here to check for edx being non-zero to indicate the list size is over 4 GB
	mul ebx

	; add bytes for the control block on the beginning of the list data
	add eax, 20

	; save the total memory size
	push eax

	; allocate the block
	push eax
	call MemAllocate
	pop edi

	; restore the saved memory size
	pop ecx

	; test the address we just got to see if it's valid
	cmp edi, 0
	jne .MemoryBlockValid

	; if we get here, the block address we got is invalid, so now it's error time
	; add code here for an error eventually
	mov eax, 0x00DEAD00
	jmp $

	.MemoryBlockValid:
	; write the data to the start of the list area, starting with the signature
	mov dword [edi], 0x7473696C
	add edi, 4

	; total size of list gets written first after being retrieved from the stack
	mov [edi], ecx
	add edi, 4

	; write the total number of elements
	pop eax
	mov [edi], eax
	add edi, 4

	; write the number of elements used
	; since this is a new list, there are a grand total of zero elements used
	mov [edi], dword 0x00000000
	add edi, 4

	; write the size of each element next
	; grab ebx that we saved at the beginning
	pop ebx
	mov [edi], ebx

	; now that everything else has been written, it's time to signature the list
	; make edi point to the proper place
	sub edi, 16

	; the memory address needs to be returned so the caller knows where the list is. duh.
	mov dword [ebp + 12], edi

	mov esp, ebp
	pop ebp
ret 4



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

	mov edi, [ebp + 8]
	mov edx, [ebp + 12]

	; check list validity
	mov eax, dword [edi]
	cmp eax, 0x7473696C
	je .ListValid

	; add error handling code here later
	mov ebp, 0xDEAD0001
	jmp $

	.ListValid:
	; our list has integrity, so let's proceed

	; first we check that the element being tested is within the range of the list
	; do to this, first we get the number of elements from the list's control block
	add edi, 8
	mov eax, [edi]
	sub edi, 8

	; now compare that to the given size of the new item
	cmp edx, eax
	jle .ElementValid

	; add error handling code here later
	mov ebp, 0xDEAD0002
	jmp $

	.ElementValid:
	; if we get here, the element is within range, so we caclulate the element's address in RAM
	; to do that, we'll need the size of each element
	add edi, 16
	mov ecx, [edi]
	sub edi, 16

	; get the address of the element in question
	mov esi, edi
	mov eax, edx
	mul ecx
	add esi, eax
	add esi, 20

	; set up a loop to check each byte of this element
	; ecx is already set up with the proper counter value from above
	mov edx, [kTrue]
	.CheckElement:
		; load a byte from the element into bl
		mov eax, esi
		add eax, ecx
		dec eax
		mov bl, [eax]

		; test bl to see if it's empty
		cmp bl, 0x00

		; decide what to do
		je .ByteEmpty

		; if we get here, the byte weasn't empty, so we set a flag
		mov edx, [kFalse]

		.ByteEmpty:
	loop .CheckElement

	; and exit
	mov dword [ebp + 12], edx

	mov esp, ebp
	pop ebp
ret 4
