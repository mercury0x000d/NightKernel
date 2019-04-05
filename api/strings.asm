; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; strings.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; 16-bit function listing:
; ConvertByteToHexString16		Translates the byte value specified to a hexadecimal number in a zero-padded 2 byte string in real mode
; ConvertWordToHexString16		Translates the word value specified to a hexadecimal number in a zero-padded 4 byte string in real mode



; 32-bit function listing:
; StringBuild					Builds a string out of the specified arguments
; StringCaseLower				Converts a string to lower case
; StringCaseUpper				Converts a string to upper case
; StringCharAppend				Appends a character onto the end of the string specified
; StringCharDelete				Deletes the character at the location specified from the string
; StringCharInsert				Inserts a character into the string at the location specified
; StringCharPrepend				Prepends a character onto the beginning of the string specified
; StringFill					Fills the entire string specified with the character specified
; StringFromBinaryValue			Translates the value specified to a binary number in a zero-padded 32 byte string
; StringFromDecimalValue		Translates the value specified to a decimal number in a zero-padded 10 byte string
; StringFromHexValue			Translates the value specified to a hexadecimal number in a zero-padded 8 byte string
; StringFromOctalValue			Translates the value specified to an octal number in a zero-padded 11 byte string
; StringLength					Returns the length of the string specified
; StringPadLeft					Pads the left side of the string specified with the character specified until it is the length specified
; StringPadRight				Pads the right side of the string specified with the character specified until it is the length specified
; StringReplaceChars			Replaces all occurrances of the specified character with another character specified
; StringReplaceCharsInRange		Replaces any character within the range of ASCII codes specified with the specified character
; StringSearchCharList			Returns the position in the string specified of the first match from a list of characters
; StringTokenReplace			Finds the first occurrance of the token ^ character replaces it with a truncated binary number
; StringTrimLeft				Trims any occurrances of the character specified off the left side of the string
; StringTrimRight				Trims any occurrances of the character specified off the right side of the string
; StringTruncateLeft			Truncates by removing the number of characters specified from the beginning of the string specified
; StringTruncateRight			Truncates by removing the number of characters specified from the end of the string specified
; StringWordCount				Counts the words in the string specified when viewed as a sentence separated by the byte specified
; StringWordGet					Returns the word specified from the string specified when separated by the byte specified





; globals
section .data
kHexDigits										db '0123456789ABCDEF'





bits 16





section .text
ConvertByteToHexString16:
	; Translates the byte value specified to a hexadecimal number in a zero-padded 2 byte string in real mode
	;
	;  input:
	;   numeric byte value
	;   string address
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov si, [bp + 4]
	mov di, [bp + 6]

	; handle digit 1
	mov cx, 0x00F0
	and cx, si
	shr cx, 4
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al
	inc di

	mov si, [bp + 4]

	; handle digit 2
	mov cx, 0x000F
	and cx, si
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al

	mov sp, bp
	pop bp
ret 4





section .text
ConvertWordToHexString16:
	; Translates the word value specified to a hexadecimal number in a zero-padded 4 byte string in real mode
	;
	;  input:
	;   numeric word value
	;   string address
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov si, [bp + 4]
	mov di, [bp + 6]


	; handle digit 1
	mov cx, 0xF000
	and cx, si
	shr cx, 12
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al
	inc di

	mov si, [bp + 4]

	; handle digit 2
	mov cx, 0x0F00
	and cx, si
	shr cx, 8
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al
	inc di

	mov si, [bp + 4]

	; handle digit 3
	mov cx, 0x00F0
	and cx, si
	shr cx, 4
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al
	inc di
	
	mov si, [bp + 4]
	
	; handle digit 4
	mov cx, 0x000F
	and cx, si
	add cx, kHexDigits
	mov si, cx
	mov al, [si]
	mov byte[di], al
	inc di

	mov sp, bp
	pop bp
ret 4





bits 32





section .text
StringBuild:
	; Builds a string out of the specified arguments
	;
	;  input:
	;   formatting string address
	;   destination string address
	;
	;  output:
	;   n/a

	pop edx
	pop esi
	pop edi

	; save the addresses for later
	mov [.sourceAddress], esi
	mov [.destAddress], edi

	; get the length of the source string
	push edx
	push esi
	call StringLength
	pop ecx
	pop edx
	mov [.sourceLength], ecx

	; init the padding value
	mov al, 0
	mov [.padding], al

	; restore the destination address
	mov edi, [.destAddress]

	.StringBuildLoop:
		mov al, [esi]

		; see if this is the "^" token
		cmp al, 94
		jne .TokenSkip

			; get the character after the token to see what we need to do
			inc esi
			mov al, [esi]

			; b		Binary
			cmp al, 98
			je .TokenBinary

			; B		Binary
			cmp al, 66
			je .TokenBinary

			; d		Decimal
			cmp al, 100
			je .TokenDecimal

			; D		Decimal
			cmp al, 68
			je .TokenDecimal

			; h		Hexadecimal
			cmp al, 104
			je .TokenHexadecimal

			; H		Hexadecimal
			cmp al, 72
			je .TokenHexadecimal

			; o		Octal
			cmp al, 111
			je .TokenOctal

			; O		Octal
			cmp al, 79
			je .TokenOctal

			; s		String
			cmp al, 115
			je .TokenString

			; S		String
			cmp al, 83
			je .TokenString

			; p		set padding value
			cmp al, 112
			je .SetPaddingValue

			; P		set padding value
			cmp al, 80
			je .SetPaddingValue

			; if we get here, there was no token match. let's just put the character itself in instead
			mov byte [edi], al
			inc edi

			jmp .TokenDone

		.TokenSkip:
		; it wasn't the token, so we just write the character directly
		mov byte [edi], al
		inc edi

		; see if this is the end of the string
		cmp al, 0
		je .LoopDone

		.TokenDone:
		inc esi
	jmp .StringBuildLoop
	.LoopDone:
	push edx
ret
; local storage
.sourceLength									dd 0x00000000
.sourceAddress									dd 0x00000000
.destAddress									dd 0x00000000
.scratch$										times 36 db 0x00
.tokenStringLength								dd 0x00000000
.temp											dd 0x00000000
.padding										db 0x00
.zero$											db '0', 0x00

; subroutines - remember, edx, esi and edi MUST BE PRESERVED to not screw up the routines above
.TokenBinary:
	; get the number
	pop eax

	; convert it to a string
	pusha
	push .scratch$
	push eax
	call StringFromBinaryValue
	popa
jmp .TokenProcessing

.TokenDecimal:
	; get the number
	pop eax

	; convert it to a string
	pusha
	push .scratch$
	push eax
	call StringFromDecimalValue
	popa
jmp .TokenProcessing

.TokenHexadecimal:
	; get the number
	pop eax

	; convert it to a string
	pusha
	push .scratch$
	push eax
	call StringFromHexValue
	popa
jmp .TokenProcessing

.TokenOctal:
	; get the number
	pop eax

	; convert it to a string
	pusha
	push .scratch$
	push eax
	call StringFromOctalValue
	popa
jmp .TokenProcessing

.TokenString:
	; get the starting address
	pop ebx

	; get its length
	pusha
	push ebx
	call StringLength
	pop eax
	mov [.tokenStringLength], eax
	popa

	; insert the temp string into our destination string
	pusha
	mov eax, [.tokenStringLength]
	push eax
	push edi
	push ebx
	call MemCopy
	popa

	; adjust the length
	mov eax, [.tokenStringLength]
	add edi, eax
jmp .TokenDone

.SetPaddingValue:
	; get the character after to see what value is there
	inc esi
	mov al, [esi]
	sub al, 48
	mov [.padding], al
jmp .TokenDone

.TokenProcessing:
	pusha

	; trim all those extra zeros
	push 48
	push .scratch$
	call StringTrimLeft

	; get the resulting string length
	push .scratch$
	call StringLength
	pop eax
	mov [.temp], eax

	; test the scratch string to see if the entire string was trimmed out (e.g. it was all zeros to begin with)
	mov eax, [.temp]
	cmp eax, 0
	jne .TokenProcessingNoAdjust

	; if we get here, the string length after trimming is 0, so lets make the number an actual zero instead
	mov esi, .scratch$
	mov byte [esi], 48
	inc esi
	mov byte [esi], 0

	; now adjust the length to reflect our changes
	mov eax, 1
	mov [.temp], eax
	.TokenProcessingNoAdjust:

	; see if the string is shorter than our padding value
	mov eax, [.temp]
	mov ebx, 0x00000000
	mov bl, [.padding]
	cmp ebx, eax
	jle .TokenProcessingNoPadding
	; if we get here, we need to pad with zeros
	.TokenProcessingPaddingLoop:
		mov esi, .scratch$
		mov edi, .zero$
		push 0
		push edi
		push esi
		call StringCharInsert

		; get the resulting string length
		push .scratch$
		call StringLength
		pop eax
		mov [.temp], eax

		; compare the length again to see if we're done
		mov eax, [.temp]
		mov ebx, 0x00000000
		mov bl, [.padding]
		cmp ebx, eax
	jg .TokenProcessingPaddingLoop

	; if we get here, padding wasn't necessary
	.TokenProcessingNoPadding:
	popa

	; insert the temp string into our destination string
	pusha
	mov eax, [.temp]
	push eax
	push edi
	push .scratch$
	call MemCopy
	popa

	; modify edi for the string length
	mov eax, [.temp]
	add edi, eax

	; clear the scratch string
	pusha
	push 0
	push 36
	push .scratch$	
	call MemFill
	popa
jmp .TokenDone





section .text
StringCaseLower:
	; Converts a string to lower case
	;
	;  input:
	;   string starting address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringLoopDone

		cmp al, 65
		jb .NotInRange

		cmp al, 90
		ja .NotInRange

		; if we get here, it was in range, so we drop it to lower case
		add al, 32
		mov [ecx], al

		.NotInRange:
		inc ecx
	jmp .StringLoop
	.StringLoopDone:

	mov esp, ebp
	pop ebp
ret 4





section .text
StringCaseUpper:
	; Converts a string to upper case
	;
	;  input:
	;   string starting address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringLoopDone

		cmp al, 97
		jb .NotInRange

		cmp al, 122
		ja .NotInRange

		; if we get here, it was in range, so we raise it to upper case
		sub al, 32
		mov [ecx], al

		.NotInRange:
		inc ecx
	jmp .StringLoop
	.StringLoopDone:

	mov esp, ebp
	pop ebp
ret 4





section .text
StringCharAppend:
	; Appends a character onto the end of the string specified
	;
	;  input:
	;   string address
	;   ASCII code of cahracter to add
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; get the length of the string passed
	push dword [ebp + 8]
	call StringLength
	pop edi
	add edi, [ebp + 8]

	; write the ASCII character
	mov eax, [ebp + 12]
	stosb

	; write a null to terminate the string
	mov al, 0
	stosb

	mov esp, ebp
	pop ebp
ret 8





section .text
StringCharDelete:
	; Deletes the character at the location specified from the string
	;
	;  input:
	;   string starting address
	;   character position to remove
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov edx, [ebp + 12]

	; test for null string for efficiency
	mov byte al, [ecx]
	cmp al, 0x00
	je .StringTrimDone

	; calculate source string position
	add ecx, edx

	; calculate the destination position
	mov edx, ecx
	dec edx

	.StringShiftLoop:
		; load a char from the source position
		mov al, [ecx]
		mov [edx], al

		; test if this is the end of the string
		cmp al, 0x00
		je .StringTrimDone

		; that wasn't the end, so we increment the pointers and do the next character
		inc edx
		inc ecx
	jmp .StringShiftLoop
	.StringTrimDone:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringCharInsert:
	; Inserts a character into the string at the location specified
	;
	;  input:
	;   main string address
	;   insert string address
	;	position after which to insert the character
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp
	sub esp, 4
	sub esp, 4

	mov ecx, [ebp + 8]
	mov edx, [ebp + 12]
	mov ebx, [ebp + 16]

	; get the length of the main string
	pusha
	push ecx
	call StringLength
	pop eax
	mov [ebp - 4], eax
	popa

	; check insert position; writing AT the end of the string is okay, PAST it is not
	mov eax, [ebp - 4]
	cmp ebx, eax
	jbe .CheckOK
	; if we get here the insert position is invalid, so we exit
	jmp .Exit
	.CheckOK:

	; get the length of the insert string
	pusha
	push edx
	call StringLength
	pop eax
	mov [ebp - 8], eax
	popa

	; set up a value to use later to check if the loop is over
	mov edx, ecx
	add edx, ebx

	; calculate address of the first byte in the section of chars to be shifted down
	add ecx, eax

	; calculate the address of the last byte of the resulting string
	mov edi, ecx
	add edi, [ebp - 8]

	.StringShiftLoop:
		; copy a byte from source to destination
		mov al, [ecx]
		mov [edi], al

		; test if we have reached the insert position
		cmp edx, edi
		je .StringTrimDone

		; that wasn't the end, so we increment the pointers and do the next character
		dec edi
		dec ecx
	jmp .StringShiftLoop

	; now that we've made room for it, we can proceed to write the insert string into the main string

	.StringTrimDone:
	; calculate the write address based on the location specified
	mov ecx, [ebp + 8]
	add ecx, ebx

	; get the address of the insert string
	mov edx, [ebp + 12]

	.StringWriteLoop:
		; get a byte from the insert string
		mov al, [edx]
		
		; see if it's null
		cmp al, 0x00
		
		; if so, jump out of the loop - we're done!
		je .StringWriteDone						

		; if we get here, it's not the end yet
		mov [ecx], al

		; increment the pointers and start over
		inc edx
		inc ecx
	jmp .StringWriteLoop
	.StringWriteDone:
	.Exit:

	mov esp, ebp
	pop ebp
ret 12





section .text
StringCharPrepend:
	; Prepends a character onto the beginning of the string specified
	;
	;  input:
	;   string address
	;   ASCII code of character to add
	;
	;  output:
	;   n/a


	push ebp
	mov ebp, esp

	; get the length of the string passed
	push dword [ebp + 8]
	call StringLength
	pop ecx
	
	; set up our string loop addresses
	mov esi, [ebp + 8]
	add esi, ecx
	mov edi, esi
	inc edi

	; loop to shift bytes down by the number of characters being inserted, plus one to allow for the null
	mov ecx, dword [ebp - 4]
	inc ecx
	pushf
	std
	.ShiftLoop:
		lodsb
		stosb
	loop .ShiftLoop
	popf

	; write the ASCII character
	mov eax, [ebp + 12]
	stosb

	mov esp, ebp
	pop ebp
ret 8





section .text
StringFill:
	; Fills the entire string specified with the character specified
	;
	;  input:
	;   string starting address
	;   fill character
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov ebx, [ebp + 12]

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringLoopDone

		mov [ecx], bl

		inc ecx
	jmp .StringLoop
	.StringLoopDone:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringFromBinaryValue:
	; Translates the value specified to a binary number in a zero-padded 32 byte string
	; Note: No length checking is done on this string; make sure it's long enough to hold the converted number!z
	;       No terminating null is put on the end of the string - do that yourself.
	;
	;  input:
	;   numeric value
	;   string address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov eax, [ebp + 8]
	mov esi, [ebp + 12]

	; clear the string to all zeroes
	pusha
	push 48
	push 32
	push esi
	call MemFill
	popa

	; add to the buffer since we start from the right (max possible length - 1)
	add esi, 31
	
	; set the divisor
	mov ebx, 2
	.DecodeLoop:
		mov edx, 0													; clear edx so we don't mess up the division
		div ebx														; divide eax by 10
		add dx, 48													; add 48 to the remainder to give us an ASCII character for this number
		mov [esi], dl
		dec esi														; move to the next position in the buffer
		cmp eax, 0
		jz .Exit													; if ax=0, end of the procedure
		jmp .DecodeLoop												; else repeat
	.Exit:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringFromDecimalValue:
	; Translates the value specified to a decimal number in a zero-padded 10 byte string
	; Note: No length checking is done on this string; make sure it's long enough to hold the converted number!
	;       No terminating null is put on the end of the string - do that yourself.
	;
	;  input:
	;   numeric value
	;   string address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov eax, [ebp + 8]
	mov esi, [ebp + 12]

	; clear the string to all zeroes
	pusha
	push 48
	push 10
	push esi
	call MemFill
	popa

	; add to the buffer since we start from the right (max possible length - 1)
	add esi, 9
	
	; set the divisor
	mov ebx, 10
	.DecodeLoop:
		mov edx, 0													; clear edx so we don't mess up the division
		div ebx														; divide eax by 10
		add dx, 48													; add 48 to the remainder to give us an ASCII character for this number
		mov [esi], dl
		dec esi														; move to the next position in the buffer
		cmp eax, 0
		jz .Exit													; if ax=0, end of the procedure
		jmp .DecodeLoop												; else repeat
	.Exit:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringFromHexValue:
	; Translates the value specified to a hexadecimal number in a zero-padded 8 byte string
	; Note: No length checking is done on this string; make sure it's long enough to hold the converted number!
	;       No terminating null is put on the end of the string - do that yourself.
	;
	;  input:
	;   numeric value
	;   string address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov esi, [ebp + 8]
	mov edi, [ebp + 12]

	mov ecx, 0xF0000000
	and ecx, esi
	shr ecx, 28
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x0F000000
	and ecx, esi
	shr ecx, 24
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x00F00000
	and ecx, esi
	shr ecx, 20
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x000F0000
	and ecx, esi
	shr ecx, 16
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x0000F000
	and ecx, esi
	shr ecx, 12
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x00000F00
	and ecx, esi
	shr ecx, 8
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x000000F0
	and ecx, esi
	shr ecx, 4
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov ecx, 0x0000000F
	and ecx, esi
	add ecx, kHexDigits
	mov al, [ecx]
	mov byte[edi], al
	inc edi

	mov esp, ebp
	pop ebp
ret 8





section .text
StringFromOctalValue:
	; Translates the value specified to an octal number in a zero-padded 11 byte string
	; Note: No length checking is done on this string; make sure it's long enough to hold the converted number!
	;       No terminating null is put on the end of the string - do that yourself.
	;
	;  input:
	;   numeric value
	;   string address
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov eax, [ebp + 8]
	mov esi, [ebp + 12]

	; clear the string to all zeroes
	pusha
	push 48
	push 11
	push esi
	call MemFill
	popa

	; add to the buffer since we start from the right (max possible length - 1)
	add esi, 10
	
	; set the divisor
	mov ebx, 8
	.DecodeLoop:
		mov edx, 0													; clear edx so we don't mess up the division
		div ebx														; divide eax by 10
		add dx, 48													; add 48 to the remainder to give us an ASCII character for this number
		mov [esi], dl
		dec esi														; move to the next position in the buffer
		cmp eax, 0
		jz .Exit													; if ax=0, end of the procedure
		jmp .DecodeLoop												; else repeat
	.Exit:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringLength:
	; Returns the length of the string specified
	;
	;  input:
	;   string starting address
	;
	;  output:
	;   string length

	push ebp
	mov ebp, esp

	mov edi, [ebp + 8]

	; set up the string scan
	mov ecx, 0xFFFFFFFF
	mov esi, edi
	mov al, 0
	repne scasb
	sub edi, esi
	dec edi

	; push the info and exit
	mov dword [ebp + 8], edi

	mov esp, ebp
	pop ebp
ret





section .text
StringPadLeft:
	; Pads the left side of the string specified with the character specified until it is the length specified
	;
	;  input:
	;   string address
	;   padding character
	;   length to which the string will be extended
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 4
	%define strLen								dword [ebp - 4]


	; get the length of the string
	push dword [ebp + 8]
	call StringLength
	pop strLen

	; exit if the string specified is already greater than the length given
	mov eax, dword [ebp + 16]
	mov ebx, strLen
	cmp ebx, eax
	jae .Exit

	; calculate number of characters we need to add into eax and save it for later
	sub eax, strLen
	push eax

	; calculate source and dest addresses
	mov esi, dword [ebp + 8]
	add esi, strLen
	mov edi, esi
	add edi, eax

	; loop to shift bytes down by the number of characters being inserted, plus one to allow for the null
	mov ecx, strLen
	inc ecx
	pushf
	std
	.ShiftLoop:
		lodsb
		stosb
	loop .ShiftLoop
	popf

	; MemFill the characters onto the beginning of the string
	pop eax
	push dword [ebp + 12]
	push eax
	push dword [ebp + 8]
	call MemFill

	.Exit:

	mov esp, ebp
	pop ebp
ret 12





section .text
StringPadRight:
	; Pads the right side of the string specified with the character specified until it is the length specified
	;
	;  input:
	;   string address
	;   padding character
	;   length to which string will be extended
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 4
	%define strLen								dword [ebp - 4]


	; get the length of the string
	push dword [ebp + 8]
	call StringLength
	pop strLen

	; exit if the string specified is already greater than the length given
	mov eax, dword [ebp + 16]
	mov ebx, strLen
	cmp ebx, eax
	jae .Exit

	; calculate number of characters we need to add into eax
	sub eax, strLen

	; calculate write address and save for later
	mov ebx, dword [ebp + 8]
	add ebx, strLen
	push ebx

	; MemFill the characters onto the end of the string
	push dword [ebp + 12]
	push eax
	push ebx
	call MemFill

	; write the null terminator
	pop ebx
	add ebx, dword [ebp + 16]
	mov byte [ebx], 0

	.Exit:

	mov esp, ebp
	pop ebp
ret 12





section .text
StringReplaceChars:
	; Replaces all occurrances of the specified character with another character specified
	;
	;  input:
	;   string starting address
	;   character to be replaced
	;   replacement character
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov ebx, [ebp + 12]
	mov edx, [ebp + 16]

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringLoopDone

		cmp al, bl
		jne .NoMatch

		; if we get here, it was in range, so replace it
		mov [ecx], dl

		.NoMatch:
		inc ecx
	jmp .StringLoop
	.StringLoopDone:

	mov esp, ebp
	pop ebp
ret 12





section .text
StringReplaceCharsInRange:
	; Replaces any character within the range of ASCII codes specified with the specified character
	;
	;  input:
	;   string starting address
	;   start of ASCII range
	;   end of ASCII range
	;   replacement character
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov eax, [ebp + 12]
	mov ebx, [ebp + 16]
	mov edx, [ebp + 20]

	mov bh, al

	; see if the range numbers are backwards and swap them if necessary
	cmp bh, bl
	jl .StringLoop
	xchg bh, bl

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringLoopDone

		cmp al, bh
		jb .NotInRange

		cmp al, bl
		ja .NotInRange

		; if we get here, it was in range, so replace it
		mov [ecx], dl

		.NotInRange:
		inc ecx
	jmp .StringLoop
	.StringLoopDone:

	mov esp, ebp
	pop ebp
ret 16





section .text
StringSearchCharList:
	; Returns the position in the string specified of the first match from a list of characters
	;
	;  input:
	;   address of string to be scanned
	;   address of character list string
	;
	;  output:
	;   position of match, or zero if no match

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 12
	%define mainStrLen							dword [ebp - 4]
	%define listStrLen							dword [ebp - 8]
	%define returnValue							dword [ebp - 12]


	; init return value to an absurdly high number 
	mov returnValue, 0xFFFFFFFF

	; get length of the main string
	push dword [ebp + 8]
	call StringLength
	pop eax

	; exit if the string was null, save eax if not
	cmp eax, 0
	je .Exit
	mov mainStrLen, eax

	; get length of the list string
	push dword [ebp + 12]
	call StringLength
	pop eax

	; exit if the string was null, save eax if not
	cmp eax, 0
	je .Exit
	mov listStrLen, eax

	; this loop cycles through all characters of the list string
	mov ecx, listStrLen
	mov esi, [ebp + 12]
	.scanLoop:

		; get a byte from the list string
		mov al, [esi]

		; preserve ecx
		mov ebx, ecx

		; scan the main string for this character
		mov ecx, mainStrLen
		mov edi, [ebp + 8]
		repne scasb

		; if the zero flag is clear, there was a match
		jnz .NextIteration
		
			; subtract the starting address of the string from edi
			; this makes it now refer to the character within the string instead of the byte address
			sub edi, [ebp + 8]

			; compare to see if this value is lower (e.g. "nearer") than the last one
			mov eax, returnValue
			cmp edi, eax
			jnb .NextIteration

			; it was closer, so save this value
			mov returnValue, edi

		.NextIteration:
		; do the next pass through the loop
		mov ecx, ebx
		inc esi
	loop .scanLoop
	
	.Exit:
	; see if the return value is still 0xFFFFFFFF and make it zero if so
	cmp returnValue, 0xFFFFFFFF
	jne .NoAdjust
	mov returnValue, 0

	.NoAdjust:
	mov eax, returnValue
	mov dword [ebp + 12], eax

	mov esp, ebp
	pop ebp
ret 4





section .text
StringTokenReplace:
	; Finds the first occurrance of the token ^ character replaces it with a truncated binary number
	;
	;  input:
	;   string address
	;   token value (to be interpreted differently depending on the token)
	;	 ^b		Binary
	;	 ^B		Binary
	;	 ^d		Decimal
	;	 ^D		Decimal
	;	 ^h		Hexadecimal
	;	 ^H		Hexadecimal
	;	 ^o		Octal
	;	 ^O		Octal
	;	 ^s		String
	;	 ^S		String
	;	 ^p		set padding value
	;	 ^P		set padding value
	;
	;  output:
	;   n/a

ret





section .text
StringTrimLeft:
	; Trims any occurrances of the character specified off the left side of the string
	;
	;  input:
	;   string starting address
	;   ASCII code of the character to be trimmed
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov ebx, [ebp + 12]

	; save the string address for later
	mov edx, ecx

	; see from where we have to start shifting
	.StringLoop:
		mov byte al, [ecx]

		cmp al, bl
		jne .StartShifting

		; if theis was the last byte of the string, then exit the loop
		cmp al, 0x00
		je .StringTrimDone

		inc ecx
	jmp .StringLoop

	.StartShifting:
	; if we get here, the current character isn't a match, so we can start shifting the characters

	; but first, a test... if ecx = edx then there's no shifting necessary and we can exit right away
	cmp ecx, edx
	je .StringTrimDone

	.StringShiftLoop:
		; load a char from the source position
		mov al, [ecx]
		mov [edx], al

		; test if this is the end of the string
		cmp al, 0x00
		je .StringTrimDone

		; that wasn't the end, so we increment the pointers and do the next character
		inc edx
		inc ecx
	jmp .StringShiftLoop
	.StringTrimDone:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringTrimRight:
	; Trims any occurrances of the character specified off the right side of the string
	;
	;  input:
	;   string starting address
	;   ASCII code of the character to be trimmed
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8]
	mov ebx, [ebp + 12]

	; get the length of the string and use it to adjust the starting pointer of the string
	push ecx
	call StringLength
	pop eax
	mov ecx, [ebp + 8]
	add ecx, eax
	dec ecx

	mov ebx, [ebp + 12]

	.StringLoop:
		mov byte al, [ecx]

		cmp al, 0x00
		je .StringTrimDone

		cmp al, bl
		jne .Truncate
		dec ecx
	jmp .StringLoop

	.Truncate:
	; adjust the pointer to the position after the last char of the string and insert the null byte
	inc ecx
	mov byte [ecx], 0

	.StringTrimDone:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringTruncateLeft:
	; Truncates the number of characters specified from the beginning of the string specified
	;
	;  input:
	;   string starting address
	;   length to which the string will be shortened
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define strLength							dword [ebp - 4]


	; get the length of the string
	push dword [ebp + 8]
	call StringLength
	pop strLength

	; exit if the string specified is shorter than the length given
	mov eax, dword [ebp + 12]
	mov ebx, strLength
	cmp eax, ebx
	jae .Exit

	; MemCopy the part of the string to be preserved
	; get the source address 
	mov esi, [ebp + 8]
	add esi, ebx
	sub esi, eax

	inc eax
	push eax
	push dword [ebp + 8]
	push esi
	call MemCopy

	.Exit:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringTruncateRight:
	; Truncates the number of characters specified from the end of the string specified
	;
	;  input:
	;   string starting address
	;   length to which the string will be shortened
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 4
	%define strLength							dword [ebp - 4]


	; get the length of the string
	push dword [ebp + 8]
	call StringLength
	pop strLength

	; exit if the string specified is shorter than the length given
	mov eax, dword [ebp + 12]
	mov ebx, strLength
	cmp eax, ebx
	jae .Exit

	; add the new length of the string to it's starting address to get our write address
	mov edi, [ebp + 8]
	add edi, eax

	; and write a null to truncate the string
	mov eax, 0
	stosb

	.Exit:

	mov esp, ebp
	pop ebp
ret 8





section .text
StringWordCount:
	; Counts the words in the string specified when viewed as a sentence separated by the byte specified
	;
	;  input:
	;   string address
	;   list of characters to be used as separators (cannot include nulls)
	;
	;  output:
	;   word count

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 15
	%define mainStrLen							dword [ebp - 4]
	%define listStrLen							dword [ebp - 8]
	%define wordCount							dword [ebp - 12]
	%define lastType							byte [ebp - 13]
	%define currentByteTemp						word [ebp - 15]


	; get eax ready for writing to the return value in case we have to exit immediately
	mov eax, 0

	; get length of the main string
	push dword [ebp + 8]
	call StringLength
	pop ebx

	; exit if the string was null, save eax if not
	cmp ebx, 0
	je .Exit
	mov mainStrLen, ebx

	; get length of the list string
	push dword [ebp + 12]
	call StringLength
	pop ebx

	; exit if the string was null, save eax if not
	cmp ebx, 0
	je .Exit
	mov listStrLen, ebx

	; set up loop value
	mov ecx, mainStrLen

	; set up local variables here
	mov lastType, 0
	mov currentByteTemp, 0
	mov wordCount, 0
	mov esi, dword [ebp + 8]

	; loop to process the characters
	.WordLoop:
		; copy a byte from the string into al
		lodsb

		; save important stuff
		push esi
		push ecx

		; see if this byte is in the list of seperators
		push dword [ebp + 12]
		mov byte [ebp - 15], al
		mov eax, ebp
		sub eax, 15
		push eax
		call StringSearchCharList
		pop edx

		; restore important stuff
		pop ecx
		pop esi

		; see if a match was found
		cmp edx, 0
		je .NotASeperator
			; make a note that this character was a separator
			mov lastType, 2
			jmp .NextIteration

		.NotASeperator:

			; if the last character wasn't a separator, increment wordCount
			mov bl, lastType

			cmp bl, 1
			je .SkipIncrement
				inc wordCount
			.SkipIncrement:

			; make a note that this character was not a separator
			mov lastType, 1

		.NextIteration:

	loop .WordLoop

	; get eax ready for writing the return value
	mov eax, wordCount

	.Exit:
	mov dword [ebp + 12], eax

	mov esp, ebp
	pop ebp
ret 4





section .text
StringWordGet:
	; Returns the word specified from the string specified when separated by the byte specified
	;
	;  input:
	;   string starting address
	;   list of characters to be used as separators (cannot include nulls)
	;	word number which to return
	;	address of string to hold the word requested
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp


	; allocate local variables
	sub esp, 15
	%define mainStrLen							dword [ebp - 4]
	%define listStrLen							dword [ebp - 8]
	%define wordCount							dword [ebp - 12]
	%define lastType							byte [ebp - 13]
	%define currentByteTemp						word [ebp - 15]


	; get eax ready for writing to the return value in case we have to exit immediately
	mov eax, 0

	; get length of the main string
	push dword [ebp + 8]
	call StringLength
	pop ebx

	; exit if the string was null, save eax if not
	cmp ebx, 0
	je .Exit
	mov mainStrLen, ebx

	; get length of the list string
	push dword [ebp + 12]
	call StringLength
	pop ebx

	; exit if the string was null, save eax if not
	cmp ebx, 0
	je .Exit
	mov listStrLen, ebx

	; set up our loop value
	mov ecx, mainStrLen

	; set up local variables here
	mov lastType, 0
	mov currentByteTemp, 0
	mov wordCount, 0
	mov esi, dword [ebp + 8]

	; clear out the temp word string
	mov edi, [ebp + 20]
	mov al, 0
	stosb

	; loop to process the characters
	.WordLoop:
		; copy a byte from the string into al
		lodsb

		; save important stuff
		push esi
		push eax
		push ecx

		; see if this byte is in the list of seperators
		push dword [ebp + 12]
		mov byte [ebp - 15], al
		mov eax, ebp
		sub eax, 15
		push eax
		call StringSearchCharList
		pop edx

		; restore important stuff
		pop ecx
		pop eax
		pop esi

		; see if a match was found
		cmp edx, 0
		je .NotASeperator
			; see if we have the requested word and exit if so
			mov eax, [ebp + 16]
			mov ebx, wordCount
			cmp eax, ebx
			je .WordFound

			; clear out wordReturned$
			mov edi, [ebp + 20]
			mov al, 0
			stosb

			; make a note that this character was a separator
			mov lastType, 2
			jmp .NextIteration

		.NotASeperator:

			; if the last character wasn't a separator, increment wordCount
			mov bl, lastType

			cmp bl, 1
			je .SkipIncrement
				inc wordCount
			.SkipIncrement:

			; make a note that this character was not a separator
			mov lastType, 1

			; add this character to wordReturned$
			pusha
			push eax
			push dword [ebp + 20]
			call StringCharAppend
			popa


		.NextIteration:

	loop .WordLoop

	.WordFound:
	; get eax ready for writing the return value
	mov eax, wordCount

	.Exit:
	mov dword [ebp + 12], eax

	mov esp, ebp
	pop ebp
ret 16
