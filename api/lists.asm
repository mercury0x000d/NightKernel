; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; lists.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





%include "include/listsDefines.inc"

%include "include/boolean.inc"
%include "include/errors.inc"
%include "include/memory.inc"





bits 32





section .text
LMBitfieldInit:
	; Creates a new bitfield from the parameters specified at the address specified
	;
	;  input:
	;	Address
	;	Number of bits
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define bitCount							dword [ebp + 12]

	; allocate local variables
	sub esp, 4
	%define bitfieldSize						dword [ebp - 4]


	; calculate the total size of the memory this list will occupy
	mov eax, bitCount
	and eax, 11111111111111111111111111111000b
	cmp eax, bitCount
	je .NoAdjust
		add eax, 8
	.NoAdjust:
	shr eax, 3
	add eax, 16
	mov bitfieldSize, eax


	; get the list ready for writing
	mov esi, address


	; write the data to the start of the list area, starting with the signature
	mov dword [esi + tListInfo.signature], 'bits'

	; write the size of each element next
	mov ebx, 0
	mov dword [esi + tListInfo.elementSize], ebx

	; write the total number of elements
	mov eax, bitCount
	mov dword [esi + tListInfo.elementCount], eax

	; write total size of list
	mov eax, bitfieldSize
	mov dword [esi + tListInfo.listSize], eax


	.Exit:
	%undef address
	%undef bitCount
	%undef bitfieldSize
	mov esp, ebp
	pop ebp
ret 8





section .text
LMBitfieldValidate:
	; Tests the bitfield specified for the 'bits' signature at the beginning
	;
	;  input:
	;	Bitfield address
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]


	; check list validity
	mov esi, address
	mov eax, dword [esi]
	mov edx, kErrBitfieldInvalid

	cmp eax, 'bits'
	jne .Exit

	mov edx, kErrNone


	.Exit:
	%undef address
	mov esp, ebp
	pop ebp
ret 4





section .text
LMBitfieldElementValidate:
	; Tests the element specified to be sure it not outside the bounds of the list
	;
	;  input:
	;	Bitfield address
	;	Element number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; check element validity
	mov esi, listPtr
	mov eax, dword [esi + tListInfo.elementCount]

	cmp elementNum, eax
	mov edx, kErrValueTooHigh
	jae .Exit

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef elementNum
	mov esp, ebp
	pop ebp
ret 8





section .text
LMBitClear:
	; Clears the bit specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if element is valid
	push element
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; get the byte and bit from the address and element
	push element
	push address
	call LM_BitfieldMath

	; modify the byte
	btr [ebx], ecx

	mov edx, kErrNone


	.Exit:
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8





section .text
LMBitClearRange:
	; Clears the range of bits specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit range start
	;	Bit range end
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define rangeStart							dword [ebp + 12]
	%define rangeEnd							dword [ebp + 16]

	; allocate local variables
	sub esp, 16
	%define startByte							dword [ebp - 4]
	%define endByte								dword [ebp - 8]
	%define startBit							dword [ebp - 12]
	%define endBit								dword [ebp - 16]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if the parameters are valid
	push rangeStart
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push rangeEnd
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; see which bytes will be at the start and end of this operation
	push rangeStart
	push address
	call LM_BitfieldMath
	mov startByte, ebx
	mov startBit, ecx

	push rangeEnd
	push address
	call LM_BitfieldMath
	mov endByte, ebx
	mov endBit, ecx


	; there's really no one-size-fits-all approach to bit range setting, so we implement three
	; (actually two and a half?) different scenarios here:
	; 1:	the range falls within a single byte
	; 2:	the range falls within two different bytes
	; 2.5:	the range already fell within two different bytes and they do not neighbor each other

	sub ebx, startByte
	cmp ebx, 0
	jne .NotASingleByte
		; if we get here, scenario 1 is true, so we can set up a simple loop to set all the bits needed in this byte
		push endBit
		push startBit
		push startByte
		call LM_ByteClearRange
		jmp .Done
	.NotASingleByte:

	; if we get here, the range operation spans multiple bytes, so we process the first and last bytes... uh... first
	push 7
	push startBit
	push startByte
	call LM_ByteClearRange

	push endBit
	push 0
	push endByte
	call LM_ByteClearRange

	; Now we check to see if those bytes were neighbors (e.g. bytes 3 and 4, or 7 and 8). If so, there's no need to do anything further.
	mov ebx, endByte
	sub ebx, startByte
	cmp ebx, 2
	jl .Done

	; If we get here, the bytes were not neighbors, meaning there's space between them we can blanket with 0x00.
	; This is MUCH more efficient than setting each byte individually in sequence.
	push 0x00
	dec ebx
	push ebx
	mov ecx, startByte
	inc ecx
	push ecx
	call MemFill


	.Done:
	mov edx, kErrNone


	.Exit:
	%undef address
	%undef rangeStart
	%undef rangeEnd
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





section .text
LMBitFlip:
	; Flips (toggles) the bit specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if element is valid
	push element
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; get the byte and bit from the address and element
	push element
	push address
	call LM_BitfieldMath


	; modify the byte
	btc [ebx], ecx

	mov edx, kErrNone


	.Exit:
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8




section .text
LMBitFlipRange:
	; Flips the range of bits specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit range start
	;	Bit range end
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define rangeStart							dword [ebp + 12]
	%define rangeEnd							dword [ebp + 16]

	; allocate local variables
	sub esp, 16
	%define startByte							dword [ebp - 4]
	%define endByte								dword [ebp - 8]
	%define startBit							dword [ebp - 12]
	%define endBit								dword [ebp - 16]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if the parameters are valid
	push rangeStart
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push rangeEnd
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; see which bytes will be at the start and end of this operation
	push rangeStart
	push address
	call LM_BitfieldMath
	mov startByte, ebx
	mov startBit, ecx

	push rangeEnd
	push address
	call LM_BitfieldMath
	mov endByte, ebx
	mov endBit, ecx


	; there's really no one-size-fits-all approach to bit range setting, so we implement three
	; (actually two and a half?) different scenarios here:
	; 1:	the range falls within a single byte
	; 2:	the range falls within two different bytes
	; 2.5:	the range already fell within two different bytes and they do not neighbor each other

	sub ebx, startByte
	cmp ebx, 0
	jne .NotASingleByte
		; if we get here, scenario 1 is true, so we can set up a simple loop to set all the bits needed in this byte
		push endBit
		push startBit
		push startByte
		call LM_ByteFlipRange
		jmp .Done
	.NotASingleByte:

	; if we get here, the range operation spans multiple bytes, so we process the first and last bytes... uh... first
	push 7
	push startBit
	push startByte
	call LM_ByteFlipRange

	push endBit
	push 0
	push endByte
	call LM_ByteFlipRange

	; Now we check to see if those bytes were neighbors (e.g. bytes 3 and 4, or 7 and 8). If so, there's no need to do anything further.
	mov ecx, endByte
	sub ecx, startByte
	cmp ecx, 2
	jl .Done

	; If we get here, the bytes were not neighbors, meaning there's space between them. We need to step through each of those whole bytes
	; and flip each one with a logical NOT.
	dec ecx
	mov ebx, startByte
	inc ebx
	.NegateLoop:
		; debug - optimize this later to process DWORDs at a time
		mov al, [ebx]
		not al
		mov [ebx], al
		inc ebx
	loop .NegateLoop


	.Done:
	mov edx, kErrNone


	.Exit:
	%undef address
	%undef rangeStart
	%undef rangeEnd
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





section .text
LMBitGet:
	; Returns the bit specified within the bitfield at the address specified
	;
	;  input:
	;	List address
	;	Bit
	;
	;  output:
	;	EDX - Error code
	;	Carry Flag - Value of the bit specified

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if element is valid
	push element
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; get the byte and bit from the address and element
	push element
	push address
	call LM_BitfieldMath

	; return the byte
	bt [ebx], ecx

	mov edx, kErrNone


	.Exit:
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8




section .text
LMBitSet:
	; Sets the bit specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if element is valid
	push element
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; get the byte and bit from the address and element
	push element
	push address
	call LM_BitfieldMath

	; modify the byte
	bts [ebx], ecx

	mov edx, kErrNone


	.Exit:
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8





section .text
LMBitSetRange:
	; Sets the range of bits specified within the bitfield at the address specified
	;
	;  input:
	;	Bitfield address
	;	Bit range start
	;	Bit range end
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define rangeStart							dword [ebp + 12]
	%define rangeEnd							dword [ebp + 16]

	; allocate local variables
	sub esp, 16
	%define startByte							dword [ebp - 4]
	%define endByte								dword [ebp - 8]
	%define startBit							dword [ebp - 12]
	%define endBit								dword [ebp - 16]


	; see if the list is valid
	push address
	call LMBitfieldValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if the parameters are valid
	push rangeStart
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push rangeEnd
	push address
	call LMBitfieldElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit


	; see which bytes will be at the start and end of this operation
	push rangeStart
	push address
	call LM_BitfieldMath
	mov startByte, ebx
	mov startBit, ecx

	push rangeEnd
	push address
	call LM_BitfieldMath
	mov endByte, ebx
	mov endBit, ecx


	; there's really no one-size-fits-all approach to bit range setting, so we implement three
	; (actually two and a half?) different scenarios here:
	; 1:	the range falls within a single byte
	; 2:	the range falls within two different bytes
	; 2.5:	the range already fell within two different bytes and they do not neighbor each other

	sub ebx, startByte
	cmp ebx, 0
	jne .NotASingleByte
		; if we get here, scenario 1 is true, so we can set up a simple loop to set all the bits needed in this byte
		push endBit
		push startBit
		push startByte
		call LM_ByteSetRange
		jmp .Done
	.NotASingleByte:

	; if we get here, the range operation spans multiple bytes, so we process the first and last bytes... uh... first
	push 7
	push startBit
	push startByte
	call LM_ByteSetRange

	push endBit
	push 0
	push endByte
	call LM_ByteSetRange

	; Now we check to see if those bytes were neighbors (e.g. bytes 3 and 4, or 7 and 8). If so, there's no need to do anything further.
	mov ebx, endByte
	sub ebx, startByte
	cmp ebx, 2
	jl .Done

	; If we get here, the bytes were not neighbors, meaning there's space between them we can blanket with 0xFF.
	; This is MUCH more efficient than setting each byte individually in sequence.
	push 0xFF
	dec ebx
	push ebx
	mov ecx, startByte
	inc ecx
	push ecx
	call MemFill


	.Done:
	mov edx, kErrNone


	.Exit:
	%undef address
	%undef rangeStart
	%undef rangeEnd
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; see if the list is valid
	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	; see if element is valid
	push elementNum
	push listPtr
	call LMElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push listPtr
	call LM_Internal_ElementAddressGet

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef elementNum
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]


	push listPtr
	call LMListValidate

	; errror check
	cmp edx, kErrNone
	jne .Exit

	push listPtr
	call LM_Internal_ElementCountGet

	mov edx, kErrNone


	.Exit:
	%undef listPtr
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define newElementCount						dword [ebp + 12]


	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push newElementCount
	push listPtr
	call LM_Internal_ElementCountSet

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef newElementCount
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push listPtr
	call LMElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push listPtr
	call LM_Internal_ElementDelete

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef elementNum
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push listPtr
	call LMElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push listPtr
	call LM_Internal_ElementDuplicate

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef elementNum
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]


	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push listPtr
	call LM_Internal_ElementSizeGet
	mov eax, edx

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	mov esp, ebp
	pop ebp
ret 8





section .text
LMElementValidate:
	; Tests the element specified to be sure it not outside the bounds of the list
	;
	;  input:
	;	List address
	;	Element number
	;
	;  output:
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define elementNum							dword [ebp + 12]


	; check element validity
	mov esi, listPtr
	mov eax, dword [esi + tListInfo.elementCount]

	cmp elementNum, eax
	mov edx, kErrValueTooHigh
	jae .Exit

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef elementNum
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define listPtr								dword [ebp + 8]
	%define slotNum								dword [ebp + 12]
	%define newItemPtr							dword [ebp + 16]
	%define newItemSize							dword [ebp + 20]


	push listPtr
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push slotNum
	push listPtr
	call LMElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push newItemSize
	push newItemPtr
	push slotNum
	push listPtr
	call LM_Internal_ItemAddAtSlot

	mov edx, kErrNone


	.Exit:
	%undef listPtr
	%undef slotNum
	%undef newItemPtr
	%undef newItemSize
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


	.Exit:
	%undef listPtr
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


	.Exit:
	%undef address
	%undef elementCount
	%undef elementSize
	%undef listSize
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]


	push address
	call LM_Internal_ListSearch


	.Exit:
	%undef address
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]


	; check list validity
	mov esi, address
	mov eax, dword [esi]
	mov edx, kErrListInvalid

	cmp eax, 'list'
	jne .Exit

	mov edx, kErrNone


	.Exit:
	%undef address
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
	;	EDX - Error code

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]


	push address
	call LMListValidate

	; error check
	cmp edx, kErrNone
	jne .Exit

	push address
	call LM_Internal_SlotFindFirstFree

	mov edx, kErrNone


	.Exit:
	%undef address
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

	; error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push address
	call LMElementValidate

	;error check
	cmp edx, kErrNone
	jne .Exit

	push elementNum
	push address
	call LM_Internal_SlotFreeTest


	.Exit:
	%undef address
	%undef elementNum
	mov esp, ebp
	pop ebp
ret 8





section .text
LM_BitfieldMath:
	; Returns the byte and bit based upon the address and erlement number specified
	; Note: This is an internal function, and is not to be called from outside the list manager.
	;
	;  input:
	;	EAX - Element
	;	ECX - 
	;
	;  output:
	;	EBX - byte address
	;	ECX - bit number

	push ebp
	mov ebp, esp

	; define input parameters
	%define address								dword [ebp + 8]
	%define element								dword [ebp + 12]


	; calculate the offset from the address of the byte containing the specific bit needed
	; this can be done by shifting to divide by 8 (byteOffset = element / 8)
	mov eax, element
	shr eax, 3

	; calculate offset of bit needed inside the byte
	; (bitOffset = element − byteOffset × 8)
	mov ebx, eax
	shl ebx, 3
	mov ecx, element
	sub ecx, ebx

	; calculate actual byte address (address = 16 + address + byteOffset)
	mov ebx, address
	add ebx, eax
	add ebx, 16


	.Exit:
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8





section .text
LM_ByteClearRange:
	; Clears a range of bits in a single byte
	; Note: This is an internal function, and is not to be called from outside the list manager.
	;
	;  input:
	;	Byte address
	;	Start of bit range
	;	End of bit range
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define byteAddress							dword [ebp + 8]
	%define startBit							dword [ebp + 12]
	%define endBit								dword [ebp + 16]


	mov ebx, byteAddress
	mov ecx, endBit
	mov edx, startBit

	.BitLoop:
		btr [ebx], ecx
		cmp ecx, edx
		je .Exit
		dec ecx
	jmp .BitLoop


	.Exit:
	%undef byteAddress
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





section .text
LM_ByteFlipRange:
	; Flips a range of bits in a single byte
	; Note: This is an internal function, and is not to be called from outside the list manager.
	;
	;  input:
	;	Byte address
	;	Start of bit range
	;	End of bit range
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define byteAddress							dword [ebp + 8]
	%define startBit							dword [ebp + 12]
	%define endBit								dword [ebp + 16]


	mov ebx, byteAddress
	mov ecx, endBit
	mov edx, startBit

	.BitLoop:
		btc [ebx], ecx
		cmp ecx, edx
		je .Exit
		dec ecx
	jmp .BitLoop


	.Exit:
	%undef byteAddress
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





section .text
LM_ByteSetRange:
	; Sets a range of bits in a single byte
	; Note: This is an internal function, and is not to be called from outside the list manager.
	;
	;  input:
	;	Byte address
	;	Start of bit range
	;	End of bit range
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define byteAddress							dword [ebp + 8]
	%define startBit							dword [ebp + 12]
	%define endBit								dword [ebp + 16]


	mov ebx, byteAddress
	mov ecx, endBit
	mov edx, startBit

	.BitLoop:
		bts [ebx], ecx
		cmp ecx, edx
		je .Exit
		dec ecx
	jmp .BitLoop


	.Exit:
	%undef byteAddress
	%undef startBit
	%undef endBit
	mov esp, ebp
	pop ebp
ret 12





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
	%undef address
	%undef elementNum
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


	.Exit:
	%undef address
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


	.Exit:
	%undef address
	%undef newSlotCount
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


	.Exit:
	%undef address
	%undef element
	%undef elementSize
	%undef elementCount
	%undef loopCounter
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


	.Exit:
	%undef address
	%undef element
	%undef elementSize
	%undef elementCount
	%undef loopCounter
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


	.Exit:
	%undef address
	mov esp, ebp
	pop ebp
ret 4





section .text
LM_Internal_ItemAddAtSlot:
	; Adds an item to the list specified at the list slot specified
	; Note: this function performs no validity checking and is only intended for use by other List Manager functions
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


	; if we get here the list passed the data integrity check, so we proceed
	; get the size of each element in this list
	mov edi, address
	push edi
	call LM_Internal_ElementSizeGet

	; now compare that to the given size of the new item
	cmp newItemSize, eax
	mov edx, kErrElementSizeInvalid

	; if we get here the size is ok, so we add it to the list!
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

	.Exit:
	%undef address
	%undef addSlot
	%undef newItemAddress
	%undef newItemSize
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
		jmp .Done

		.ElementNotEmpty:
		inc edx

	; see if we're done here
	mov ecx, [esi + tListInfo.elementCount]
	cmp edx, ecx
	jne .FindLoop

	.Done:
	mov eax, edx


	.Exit:
	%undef address
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
	%undef address
	%undef element
	mov esp, ebp
	pop ebp
ret 8
