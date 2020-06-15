; Night Kernel
; Copyright 2015 - 2020 by Mercury 0x0D
; screen.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; includes
%include "include/screenDefines.inc"

%include "include/globals.inc"
%include "include/memory.inc"
%include "include/strings.inc"





section .data

; globals
gCursorX										db 0x01
gCursorY										db 0x01
gTextColor										db 0x07
gBackColor										db 0x00
kMaxLines										db 25
kBytesPerScreen									dw 4000





bits 16





section .text
Print16:
	; Prints an ASCIIZ string directly to the screen.
	; Note: For use in Real Mode only.
	; Note: This function isn't as robust as its 32-bit cousin because... well... it doesn't need to be.
	; Note: Another you-know-what.
	; Note: No! Not another note!
	; Note: Yes, another! And another! Until you come to your senses!
	;
	;  input:
	;	Address of string to print
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp

	; define input parameters
	%define stringPtr							word [bp + 4]

	; allocate local variables
	sub sp, 1
	%define scratchByte							byte [bp - 1]


	; see if we need to scroll the output
	mov bl, byte [kMaxLines]
	mov al, byte [gCursorY]
	cmp al, bl
	jbe .SkipScroll
		; if we get here, we need to scroll the display

		; see how many lines need scrolled
		sub al, bl
		and eax, 0x000000FF
		push dword eax
		call ScreenScroll16
	.SkipScroll:

	mov si, stringPtr
	
	; preserve es
	push es

	; set up the foreground and background colors
	mov bl, [gBackColor]
	mov cl, [gTextColor]
	and bx, 0x0F
	and cx, 0x0F

	rol bl, 4
	or cl, bl
	mov scratchByte, cl

	; set up the segment
	mov ax, 0xB800
	mov es, ax
	mov di, 0x0000
	mov ax, 0x0000

	; adjust di for horizontal position
	mov ax, 0x0000
	mov al, [gCursorX]
	dec ax
	shl ax, 1
	mov bx, di
	add bx, ax
	mov di, bx

	; adjust di for vertical position
	mov ax, 0x0000
	mov al, [gCursorY]
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
	mov bl, scratchByte

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
	mov byte [gCursorX], 1

	; update cursor Y position
	mov al, [gCursorY]
	inc al
	mov [gCursorY], al

	; restore es
	pop es


	.Exit:
	%undef stringPtr
	%undef scratchByte
	mov sp, bp
	pop bp
ret 2





section .text
PrintIfConfigBits16:
	; Prints an ASCIIZ string directly to the screen only if the configbits option is set
	;
	;  input:
	;	Address of string to print
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp

	; define input parameters
	%define stringPtr							word [bp + 4]


	bt dword [tSystem.configBits], kCBVerbose
	jnc .Exit

	push stringPtr
	call Print16

	.Exit:
	%undef stringPtr
	mov sp, bp
	pop bp
ret 2





section .text
PrintRegs16:
	; Quick register dump routine for real mode
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; pusha for printing
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
ret

section .data
.output1$										db ' AX 0000    BX 0000    CX 0000    DX 0000 ', 0x00
.output2$										db ' SI 0000    DI 0000    SP 0000    BP 0000 ', 0x00





section .text
ScreenClear16:
	; Clears the text mode screen
	; Note: For use in Protected Mode only
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp

	mov cx, 0xB800
	mov gs, cx
	mov si, 0

	; set up the word we're writing
	xor ax, ax
	mov ah, byte [gBackColor]
	shl ah, 4

	; set up the loop value
	mov cx, word [kBytesPerScreen]

	; divide by 2 since we're writing words
	shr ecx, 1

	.aloop:
		mov word [gs:si], ax
		add si, 2
	loop .aloop

	; reset the cursor position
	mov byte [gCursorX], 1
	mov byte [gCursorY], 1

	mov sp, bp
	pop bp
ret





section .text
ScreenScroll16:
	; Scrolls the text mode screen by the specified number of lines
	;
	;  input:
	;	Number of lines to scroll
	;
	;  output:
	;	n/a

	push bp
	mov bp, sp


	; define input parameters
	%define lineCount							word [ebp + 4]


	mov cx, lineCount

	.ScrollLoop:
		; preserve the line counter
		mov lineCount, cx

		mov ecx, dword [kBytesPerScreen]

		; divide the counter by 8 since we're copying that many bytes at a time
		shr ecx, 3

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

		; restore line counter
		mov cx, lineCount
	loop .ScrollLoop

	; update the cursor Y position
	mov al, byte [kMaxLines]
	mov byte [gCursorY], al


	.Exit:
	%undef lineCount
	mov sp, bp
	pop bp
ret 2





bits 32





section .text
CursorHome:
	; Returns the text mode cursor to the "home" (upper left) position
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	mov byte [gCursorX], 1
	mov byte [gCursorY], 1

	mov esp, ebp
	pop ebp
ret





section .text
Print32:
	; Prints an ASCIIZ string directly to the screen.
	;
	;  input:
	;	Address of string to print
	;	X position
	;	Y position
	;	Foreground color
	;	Background color
	;
	;  output:
	;	AL - Updated X position
	;	AH - Updated Y position

	push ebp
	mov ebp, esp

	; allocate local variables
	sub esp, 5
	%define cursorX								byte [ebp - 1]
	%define cursorY								byte [ebp - 2]
	%define textColor							byte [ebp - 3]
	%define backColor							byte [ebp - 4]
	%define tempByte							byte [ebp - 5]


	; load parameters into local variables
	mov eax, dword [ebp + 12]
	mov cursorX, al

	mov eax, dword [ebp + 16]
	mov cursorY, al

	mov eax, dword [ebp + 20]
	mov textColor, al

	mov eax, dword [ebp + 24]
	mov backColor, al


	; see if we need to scroll
	mov bl, byte [kMaxLines]
	mov al, byte [gCursorY]
	cmp al, bl
	jbe .SkipScroll
		; if we get here, we need to scroll the display

		; see how many lines need scrolled
		sub al, bl
		and eax, 0x000000FF
		push dword eax
		call ScreenScroll32

		; update the cursor Y position
		mov al, byte [kMaxLines]
		mov cursorY, al

	.SkipScroll:


	mov esi, [ebp + 8]
	
	; set up the foreground and background colors
	mov bl, backColor
	mov cl, textColor
	and bx, 0x0F
	and cx, 0x0F

	rol bl, 4
	or cl, bl
	mov tempByte, cl

	; set up the pointer
	mov edi, 0xB8000

	; adjust di for horizontal position
	mov ax, 0x0000
	mov al, cursorX
	dec ax
	shl ax, 1
	mov bx, di
	add bx, ax
	mov di, bx

	; adjust di for vertical position
	mov ax, 0x0000
	mov al, cursorY
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
	mov cursorX, 1

	; update cursor Y position
	mov al, cursorY
	inc al
	mov cursorY, al


	; return the resulting cursor values to the caller
	mov al, cursorX
	mov ah, cursorY


	.Exit:
	%undef cursorX
	%undef cursorY
	%undef textColor
	%undef backColor
	%undef tempByte
	mov esp, ebp
	pop ebp
ret 20





section .text
PrintIfConfigBits32:
	; Prints an ASCIIZ string directly to the screen only if the configbits option is set
	;
	;  input:
	;	Address of string to print
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	bt dword [tSystem.configBits], kCBVerbose
	jnc .NoPrint

		; if we get here, we need to print
		mov eax, 0x00000000

		push dword 0x00000000
		push dword 0x00000007

		mov al, byte [gCursorY]
		push dword eax

		mov al, byte [gCursorX]
		push dword eax

		push dword [ebp + 8]
		call Print32

		mov byte [gCursorX], al
		mov byte [gCursorY], ah

	.NoPrint:
	mov esp, ebp
	pop ebp
ret 4





section .text
PrintRAM32:
	; Prints a range of RAM bytes to the screen
	;
	;  input:
	;	Starting address
	;	Number of 16-byte lines
	;	X position
	;	Y position
	;	Text color
	;	Background color
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp


	; define input parameters
	%define address								dword [ebp + 8]
	%define lineCount							dword [ebp + 12]
	%define XPos								dword [ebp + 16]
	%define YPos								dword [ebp + 20]
	%define frontColor							dword [ebp + 24]
	%define backColor							dword [ebp + 28]

	; allocate local variables
	sub esp, 4
	%define byteCounter							dword [ebp - 4]

	; load parameters into local variables
	mov eax, address
	mov address, eax

	mov ecx, lineCount


	.LineLoop:
		; update the line counter
		mov lineCount, ecx


		; prep the print strings
		push dword 80
		push .scratch$
		push .format$
		call MemCopy

		push dword 46
		push dword 16
		push .ASCII$
		call MemFill

		mov esi, .ASCII$
		add esi, 16
		mov byte [esi], 0


		; write the starting address for this line to the string
		push dword 8
		push address
		push .scratch$
		call StringTokenHexadecimal


		mov ecx, 16
		.BytesLoad:
			; update the line counter
			mov byteCounter, ecx

			; load a byte from RAM
			mov eax, 0x00000000
			mov esi, address
			lodsb

			; see if this byte is in printable range
			cmp al, 32
			jb .NotInRange
			
			cmp al, 127
			ja .NotInRange

			; if we get here, the byte was in range
			; so we need to write it into the scratch string
			mov esi, .ASCII$
			mov ebx, 16
			sub ebx, ecx
			add esi, ebx
			mov byte [esi], al


			.NotInRange:
			; process this byte into the string
			push dword 2
			push eax
			push .scratch$
			call StringTokenHexadecimal

			; increment the byte counter
			inc address

			mov ecx, byteCounter
		loop .BytesLoad


		; add the ASCII dump string into the line string
		push dword 0
		push .ASCII$
		push .scratch$
		call StringTokenString


		; print the string we just built
		push backColor
		push frontColor
		push YPos
		push dword 1
		push .scratch$
		call Print32

		xor ebx, ebx
		mov bl, ah
		mov YPos, ebx

		mov ecx, lineCount
	dec ecx
	cmp ecx, 0
	jne .LineLoop


	.Exit:
	%undef address
	%undef lineCount
	%undef XPos
	%undef YPos
	%undef frontColor
	%undef backColor
	%undef byteCounter
	mov esp, ebp
	pop ebp
ret 24

section .data
.format$										db ' 0x^  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^  ^ ', 0x00

section .bss
.scratch$										resb 80
.ASCII$											resb 17





section .text
PrintRegs32:
	; Quick register dump routine for protected mode
	;
	;  input:
	;	n/a
	;
	;  output:
	;	n/a


	; pusha for printing
	pusha

	; get edi
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 21
	push ebx
	push eax
	call ConvertNumberHexToString


	; get esi
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 5
	push ebx
	push eax
	call ConvertNumberHexToString


	; get ebp
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 53
	push ebx
	push eax
	call ConvertNumberHexToString


	; get esp
	pop eax

	; convert it to a string
	mov ebx, .output2$
	add ebx, 37
	push ebx
	push eax
	call ConvertNumberHexToString


	; get ebx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 21
	push ebx
	push eax
	call ConvertNumberHexToString


	; get edx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 53
	push ebx
	push eax
	call ConvertNumberHexToString


	; get ecx
	pop eax

	; convert it to a string
	mov ebx, .output1$
	add ebx, 37
	push ebx
	push eax
	call ConvertNumberHexToString


	; get eax
	pop eax

	; convert it to a string
	mov bx, .output1$
	add bx, 5
	push ebx
	push eax
	call ConvertNumberHexToString


	; print the strings
	mov eax, 0x00000000

	push dword 0x00000000
	push dword 0x00000007

	mov al, byte [gCursorY]
	push dword eax

	mov al, byte [gCursorX]
	push dword eax

	push .output1$
	call Print32

	mov byte [gCursorX], al
	mov byte [gCursorY], ah


	mov eax, 0x00000000

	push dword 0x00000000
	push dword 0x00000007

	mov al, byte [gCursorY]
	push dword eax

	mov al, byte [gCursorX]
	push dword eax

	push .output2$
	call Print32

	mov byte [gCursorX], al
	mov byte [gCursorY], ah
ret

section .data
.output1$										db ' EAX 00000000    EBX 00000000    ECX 00000000    EDX 00000000 ', 0x00
.output2$										db ' ESI 00000000    EDI 00000000    ESP 00000000    EBP 00000000 ', 0x00





section .text
ScreenClear32:
	; Clears the text mode screen
	;
	;  input:
	;	Color to which the screen will be cleared
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define clearColor							dword [ebp + 8]


	; see how many bytes make up this screen mode
	mov cx, word [kBytesPerScreen]

	; load the write address
	mov esi, 0xB8000

	; divide by 2 since we're writing words
	shr ecx, 1

	; set up the word we're writing
	mov ebx, clearColor
	xor ax, ax
	mov ah, bl
	shl ah, 4

	.aloop:
		mov word [esi], ax
		add esi, 2
	loop .aloop, cx

	; reset the cursor position
	call CursorHome


	.Exit:
	%undef clearColor
	mov esp, ebp
	pop ebp
ret 4





section .text
ScreenScroll32:
	; Scrolls the text mode screen by the specified number of lines
	;
	;  input:
	;	Number of lines to scroll
	;
	;  output:
	;	n/a

	push ebp
	mov ebp, esp

	; define input parameters
	%define lineCount							dword [ebp + 8]


	; catalyze the loop
	mov ecx, lineCount
	.ScrollLoop:
		; preserve the line counter
		mov lineCount, ecx

		; scroll one line
		push dword [kBytesPerScreen]
		push dword 0x0000B8000
		push dword 0x0000B80A0
		call MemCopy

		; restore line counter
		mov ecx, lineCount
	loop .ScrollLoop


	.Exit:
	%undef lineCount
	mov esp, ebp
	pop ebp
ret 4
