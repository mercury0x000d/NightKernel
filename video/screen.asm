; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; screen.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 16-bit function listing:
; ScreenClear16					Clears the text mode screen
; Print16						Prints an ASCIIZ string directly to the screen
; PrintIfConfigBits16			Prints an ASCIIZ string directly to the screen only if the configbits option is set
; PrintRegs16					Quick register dump routine for real mode

; 32-bit function listing:
; ScreenClear32					Clears the text mode screen
; CursorHome					Returns the text mode cursor to the "home" (upper left) position
; Print32						Prints an ASCIIZ string directly to the screen
; PrintIfConfigBits32			Prints an ASCIIZ string directly to the screen only if the configbits option is set
; PrintRAM32					Prints a range of RAM bytes to the screen
; PrintRegs32					Quick register dump routine for protected mode



; globals
cursorX											db 0x01
cursorY											db 0x01
textColor										db 0x07
backColor										db 0x00
kMaxLines										db 25
kBytesPerScreen									dw 4000



bits 16



Print16:
	; Prints an ASCIIZ string directly to the screen.
	; Note: Uses text mode (assumed already set) not VESA.
	; Note: For use in Real Mode only.
	;
	;  input:
	;   address of string to print
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp
	sub sp, 1

	mov si, [ebp + 4]
	
	; preserve es
	push es

	; set up the foreground and background colors
	mov bl, [backColor]
	mov cl, [textColor]
	and bx, 0x0F
	and cx, 0x0F

	rol bl, 4
	or cl, bl
	mov [bp - 1], cl

	; set up the segment
	mov ax, 0xB800
	mov es, ax
	mov di, 0x0000
	mov ax, 0x0000

	; adjust di for horizontal position
	mov ax, 0x0000
	mov al, [cursorX]
	dec ax
	shl ax, 1
	mov bx, di
	add bx, ax
	mov di, bx

	; adjust di for vertical position
	mov ax, 0x0000
	mov al, [cursorY]
	dec ax

	; use a pair of shifts to multiply by 80
	mov bx, ax
	shl ax, 6
	shl bx, 4
	add ax, bx

	; use a shift to multiply by 2 to allow for the fact that it takes 2 bytes to render a single character to the screen
	shl ax, 1

	mov bx, di
	add bx, ax
	mov di, bx

	; load the color attribute to bl
	mov bl, [bp - 1]

	.loopBegin:
		lodsb
		; have we reached the string end? if yes, exit the loop
		cmp al, 0x00
		je .end

		mov byte[es:di], al
		inc di
		mov byte[es:di], bl
		inc di
	jmp .loopBegin
	.end:

	; update cursor X position
	mov byte [cursorX], 1

	; update cursor Y position
	mov al, [cursorY]
	inc al
	mov [cursorY], al

	; see if we need to scroll the output
	mov bl, byte [kMaxLines]
	inc bl
	cmp al, bl
	jne .SkipScroll

		; if we get here, we need to scroll the display
		mov cx, word [kBytesPerScreen]

		; divide the counter by 8 since we're copying that many bytes at a time
		shr cx, 3

		mov ax, 0xB800
		mov si, 160
		mov di, 0
		mov gs, ax
		.copyLoop:
			; read data in
			mov eax, [gs:si]
			add si, 4
			mov ebx, [gs:si]
			add si, 4
			
			; write data out
			mov [gs:di], eax
			add di, 4
			mov [gs:di], ebx
			add di, 4
		loop .copyLoop

		; update the cursor Y position
		mov al, byte [kMaxLines]
		mov byte [cursorY], al

	.SkipScroll:
	; restore es
	pop es

	mov sp, bp
	pop bp
ret 2



PrintIfConfigBits16:
	; Prints an ASCIIZ string directly to the screen only if the configbits option is set
	;
	;  input:
	;   address of string to print (bp + 4)
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov eax, dword [tSystem.configBits]
	and eax, 000000000000000000000000000000010b
	cmp eax, 000000000000000000000000000000010b
	jne .NoPrint

	push word [bp + 4]
	call Print16

	.NoPrint:
	mov sp, bp
	pop bp
ret 2



PrintRegs16:
	; Quick register dump routine for real mode
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	; push all once to save the registers
	pusha
	pushf

	; pusha once more for printing
	pusha

	; get di
	pop ax

	; convert it to a string
	mov bx, .output2$
	add bx, 15
	push bx
	push ax
	call ConvertWordToHexString16


	; get si
	pop ax

	; convert it to a string
	mov bx, .output2$
	add bx, 4
	push bx
	push ax
	call ConvertWordToHexString16


	; get bp
	pop ax

	; convert it to a string
	mov bx, .output2$
	add bx, 37
	push bx
	push ax
	call ConvertWordToHexString16


	; get sp
	pop ax

	; convert it to a string
	mov bx, .output2$
	add bx, 26
	push bx
	push ax
	call ConvertWordToHexString16


	; get bx
	pop ax

	; convert it to a string
	mov bx, .output1$
	add bx, 15
	push bx
	push ax
	call ConvertWordToHexString16


	; get dx
	pop ax

	; convert it to a string
	mov bx, .output1$
	add bx, 37
	push bx
	push ax
	call ConvertWordToHexString16


	; get cx
	pop ax

	; convert it to a string
	mov bx, .output1$
	add bx, 26
	push bx
	push ax
	call ConvertWordToHexString16


	; get ax
	pop ax

	; convert it to a string
	mov bx, .output1$
	add bx, 4
	push bx
	push ax
	call ConvertWordToHexString16

	push .output1$
	call Print16

	push .output2$
	call Print16

	popf
	popa

	mov sp, bp
	pop bp
ret
.output1$										db ' AX 0000    BX 0000    CX 0000    DX 0000 ', 0x00
.output2$										db ' SI 0000    DI 0000    SP 0000    BP 0000 ', 0x00



ScreenClear16:
	; Clears the text mode screen
	; Note: For use in Protected Mode only
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push bp
	mov bp, sp

	mov cx, 0xB800
	mov gs, cx
	mov si, 0

	; set up the word we're writing
	xor ax, ax
	mov ah, byte [backColor]
	shl ah, 4

	; set up the loop value
	mov cx, word [kBytesPerScreen]

	; divide by 2 since we're writing words
	shl ecx, 1

	.aloop:
		mov word [gs:si], ax
		add si, 2
	loop .aloop

	; reset the cursor position
	mov byte [cursorX], 1
	mov byte [cursorY], 1

	mov sp, bp
	pop bp
ret



bits 32



CursorHome:
	; Returns the text mode cursor to the "home" (upper left) position
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov byte [cursorX], 1
	mov byte [cursorY], 1

	mov esp, ebp
	pop ebp
ret



Print32:
	; Prints an ASCIIZ string directly to the screen.
	; Note: Uses text mode (assumed already set) not VESA.
	; Note: For use in Real Mode only.
	;
	;  input:
	;   address of string to print
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 1
	%define tempByte							byte [ebp - 1]


	mov esi, [ebp + 8]
	
	; set up the foreground and background colors
	mov bl, [backColor]
	mov cl, [textColor]
	and bx, 0x0F
	and cx, 0x0F

	rol bl, 4
	or cl, bl
	mov tempByte, cl

	; set up the pointer
	mov edi, 0xB8000

	; adjust di for horizontal position
	mov ax, 0x0000
	mov al, [cursorX]
	dec ax
	shl ax, 1
	mov bx, di
	add bx, ax
	mov di, bx

	; adjust di for vertical position
	mov ax, 0x0000
	mov al, [cursorY]
	dec ax

	; use a pair of shifts to multiply by 80
	mov bx, ax
	shl ax, 6
	shl bx, 4
	add ax, bx

	; use a shift to multiply by 2 to allow for the fact that it takes 2 bytes to render a single character to the screen
	shl ax, 1

	mov bx, di
	add bx, ax
	mov di, bx

	; load the color attribute to bl
	mov bl, tempByte

	.loopBegin:
		lodsb
		; have we reached the string end? if yes, exit the loop
		cmp al, 0x00
		je .end

		mov byte[edi], al
		inc edi
		mov byte[edi], bl
		inc edi
	jmp .loopBegin
	.end:

	; update cursor X position
	mov byte [cursorX], 1

	; update cursor Y position
	mov al, [cursorY]
	inc al
	mov [cursorY], al

	; see if we need to scroll the output
	mov bl, byte [kMaxLines]
	inc bl
	cmp al, bl
	jne .SkipScroll

		; if we get here, we need to scroll the display
		mov eax, 0x00000000
		mov ax, word [kBytesPerScreen]
		mov ecx, eax

		; divide the counter by 8 since we're copying that many bytes at a time
		shr ecx, 3

		mov esi, 0xB80A0
		mov edi, 0xB8000
		.copyLoop:
			; read data in
			mov eax, [esi]
			add esi, 4
			mov ebx, [esi]
			add esi, 4
			
			; write data out
			mov [edi], eax
			add edi, 4
			mov [edi], ebx
			add edi, 4
		loop .copyLoop

		; update the cursor Y position
		mov al, byte [kMaxLines]
		mov byte [cursorY], al

	.SkipScroll:

	mov esp, ebp
	pop ebp
ret 4



PrintIfConfigBits32:
	; Prints an ASCIIZ string directly to the screen only if the configbits option is set
	;
	;  input:
	;   address of string to print
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov eax, [tSystem.configBits]
	and eax, 000000000000000000000000000000010b
	cmp eax, 000000000000000000000000000000010b
	jne .NoPrint

	push dword [ebp + 8]
	call Print32

	.NoPrint:

	mov esp, ebp
	pop ebp
ret 4



PrintRAM32:
	; Prints a range of RAM bytes to the screen
	;
	;  input:
	;   starting address
	;	number of lines
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 17									; space for ASCII dump
	sub esp, 81									; space for address and hex dunp

	mov edi, [ebp + 8]
	mov ecx, [ebp + 12]

	; throw a null on the end of the ascii string
	mov byte [ebp - 1], 0

	.LineLoop:
		; save the line counter and address pointer
		push ecx
		push edi

		pusha

		; clear the output string, otherwise StringBuild() will throw a fit. Possible bug?
		push 0
		push 80
		mov eax, ebp
		sub eax, 98
		push eax
		call MemFill

		; clear the ASCII string too
		push 46
		push 16
		mov eax, ebp
		sub eax, 17
		push eax
		call MemFill

		popa

		; set up some variables for the future
		mov esi, edi
		mov ebx, ebp
		sub ebx, 17

		; load the address of the ASCII text string to the stack for StringBuild()
		push ebx

		; load 16 bytes to the stack
		mov eax, 0x00000000
		mov ecx, 16
		add edi, 15
		.BytesLoad:
			; load a byte to the stack for the hex sequence section...
			mov al, [edi]
			dec edi
			push eax

			; ...and load a byte to the ASCII section
			lodsb

			; add that byte to the ASCII string if it's in printable range
			cmp al, 32
			jb .NotInRange
			
			cmp al, 127
			ja .NotInRange

			.IsInRange:
			mov [ebx], al

			.NotInRange:
			inc ebx
		loop .BytesLoad

		; set up the rest of the StringBuild() call
		inc edi
		push edi
		mov eax, ebp
		sub eax, 98
		push eax
		push .format$
		call StringBuild

		; print the string we just built
		mov eax, ebp
		sub eax, 98
		push eax
		call Print32

		; restore our values
		pop edi
		pop ecx
		add edi, 16
	loop .LineLoop

	mov esp, ebp
	pop ebp
ret 8
.format$										db '^p8 ^h  ^p2 ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h ^h   ^s ', 0x00



PrintRegs32:
	; Quick register dump routine for protected mode
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; push all once to save the registers
	pusha
	pushf

	; pusha once more for printing
	pusha

	; get di
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 21
	push ebx
	push eax
	call StringFromHexValue


	; get si
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 5
	push ebx
	push eax
	call StringFromHexValue


	; get bp
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 53
	push ebx
	push eax
	call StringFromHexValue


	; get sp
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 37
	push ebx
	push eax
	call StringFromHexValue


	; get bx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 21
	push ebx
	push eax
	call StringFromHexValue


	; get dx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 53
	push ebx
	push eax
	call StringFromHexValue


	; get cx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 37
	push ebx
	push eax
	call StringFromHexValue


	; get ax
	pop eax

	; convert it to a string
	mov bx, .output1$
	add bx, 5
	push ebx
	push eax
	call StringFromHexValue

	push .output1$
	call Print32

	push .output2$
	call Print32

	popf
	popa

	mov esp, ebp
	pop ebp
ret
.output1$										db ' EAX 00000000    EBX 00000000    ECX 00000000    EDX 00000000 ', 0x00
.output2$										db ' ESI 00000000    EDI 00000000    ESP 00000000    EBP 00000000 ', 0x00



ScreenClear32:
	; Clears the text mode screen
	; Note: For use in Protected Mode only
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; see how many bytes make up this screen mode
	mov cx, word [kBytesPerScreen]

	; load the write address
	mov esi, 0xB8000

	; divide by 2 since we're writing words
	shl ecx, 1

	; set up the word we're writing
	xor ax, ax
	mov ah, byte [backColor]
	shl ah, 4

	.aloop:
		mov word [esi], ax
		add esi, 2
	loop .aloop, cx

	; reset the cursor position
	call CursorHome

	mov esp, ebp
	pop ebp
ret
