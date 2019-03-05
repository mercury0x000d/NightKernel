; Night Kernel
; Copyright 1995 - 2019 by mercury0x0d
; ps2.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.



; 32-bit function listing:
; SerialGetBaud					Returns the current baud rate of the specified serial port
; KeyboardInit					Initializes the PS/2 keyboard
; KeyboardNumLockSet			Handles the internals of turning on Num Lock - sets the flag and turns on the LED
; KeyGet						Returns the oldest key in the key buffer, or null if it's empty
; KeyWait						Waits until a key is pressed, then returns that key
; MouseInit						Initializes the PS/2 mouse
; PS2ControllerWaitDataRead		Reads data from the PS/2 controller
; PS2ControllerWaitDataWrite	Waits with timeout until the PS/2 controller is ready to accept data, then returns



; globals
; make the key buffer allocated in the future
kKeyBufferWrite									db 0x00
kKeyBufferRead									db 0x00
kKeyBuffer										times 256 db 0x00



bits 32



KeyboardInit:
	; Initializes the PS/2 keyboard
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	call PS2ControllerWaitDataWrite
	mov al, 0xFF
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	; if not 0xFA, then the keyboard is missing or not responding

	; wait 5 seconds-ish for the keyboard to say the reset is done
	mov bl, 5
	mov bh, 0x00
	.loop:
		; check the keyboard status
		pusha
		call PS2ControllerWaitDataRead
		popa
		in al, 0x60
		cmp al, 0xAA
		je .resetDone
		inc bh
		cmp bl, bh
	jne .loop
	.resetDone:

	; now we set the custom stuff
	mov ebx, [tSystem.delayValue]
	shr ebx, 2
	push ebx

	; illuminate scroll lock
	call PS2ControllerWaitDataWrite
	mov al, 0xED
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000001b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	pop ebx
	push ebx
	mov ecx, 0x00000000
	.loopA:
		inc ecx
		cmp ebx, ecx
	jne .loopA

	; set autorepeat delay and rate to fastest available
	call PS2ControllerWaitDataWrite
	mov al, 0xF3
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000000b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; illuminate caps lock
	call PS2ControllerWaitDataWrite
	mov al, 0xED
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000100b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	pop ebx
	push ebx
	mov ecx, 0x00000000
	.loopB:
		inc ecx
		cmp ebx, ecx
	jne .loopB

	; set scan code set to 2
	call PS2ControllerWaitDataWrite
	mov al, 0xF0
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000010b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; illuminate num lock
	call PS2ControllerWaitDataWrite
	mov al, 0xED
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000010b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	pop ebx
	mov ecx, 0x00000000
	.loopC:
		inc ecx
		cmp ebx, ecx
	jne .loopC

	; get ID bytes
	call PS2ControllerWaitDataWrite
	mov al, 0xF2
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataRead
	in al, 0x60
	mov edx, tSystem.keyboardType
	inc edx
	mov [edx] ,al
	call PS2ControllerWaitDataRead
	in al, 0x60
	dec edx
	mov [edx] ,al

	; enable num lock
	call KeyboardNumLockSet

	mov esp, ebp
	pop ebp
ret



KeyboardNumLockSet:
	; Handles the internals of turning on Num Lock - sets the flag and turns on the LED
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; right now we just illuminate num lock
	; once we figure out how the kernel keeps track of lock modifiers, that will get added in too
	call PS2ControllerWaitDataWrite
	mov al, 0xED
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 00000010b
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	mov esp, ebp
	pop ebp
ret



KeyGet:
	; Returns the oldest key in the key buffer, or null if it's empty
	;
	;  input:
	;   dummy value
	;
	;  output:
	;   key pressed in lowest byte of 32-bit value

	push ebp
	mov ebp, esp

	mov eax, 0x00000000
	mov ecx, 0x00000000
	mov edx, 0x00000000

	; load the buffer positions
	mov cl, [kKeyBufferRead]
	mov dl, [kKeyBufferWrite]

	; if the read position is the same as the write position, the buffer is empty and we can exit
	cmp dl, cl
	je .done

	; calculate the read address into esi
	mov esi, kKeyBuffer
	add esi, ecx

	; get the byte to return into al
	mov byte al, [esi]

	; update the read position
	inc cl
	mov byte [kKeyBufferRead], cl

	.done:
	; push the data we got onto the stack and exit
	mov dword [ebp + 8], eax

	mov esp, ebp
	pop ebp
ret



KeyWait:
	; Waits until a key is pressed, then returns that key
	;
	;  input:
	;   dummy value
	;
	;  output:
	;   key code

	push ebp
	mov ebp, esp

	.KeyLoop:
		push 0
		call KeyGet
		pop eax
		cmp al, 0x00
	je .KeyLoop

	mov dword [ebp + 8], eax
	mov esp, ebp
	pop ebp
ret



MouseInit:
	; Initializes the PS/2 mouse
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	; disable keyboard temporarily
	call PS2ControllerWaitDataWrite
	mov al, 0xAD
	out 0x64, al

	; enable mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xA8
	out 0x64, al

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al

	; reset command
	call PS2ControllerWaitDataWrite
	mov al, 0xFF
	out 0x60, al

	call PS2ControllerWaitDataRead
	in al, 0x60

	; wait 5 seconds-ish for the mouse to say the reset is done
	mov bl, 5
	mov bh, 0x00
	.loop:
		; check the mouse status
		pusha
		call PS2ControllerWaitDataRead
		popa
		in al, 0x60
		cmp al, 0xAA
		je .resetDone
		inc bh
		cmp bl, bh
	jne .loop
	.resetDone:
	; read mouse ID byte
	call PS2ControllerWaitDataRead
	in al, 0x60

	; get controller configuration byte
	call PS2ControllerWaitDataWrite
	mov al, 0x20
	out 0x64, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; modify the proper bits to enable IRQ and mouse clock
	or al, 00000010b
	and al, 11011111b
	push eax

	; write controller configuration byte
	call PS2ControllerWaitDataWrite
	mov al, 0x60
	out 0x64, al
	call PS2ControllerWaitDataWrite
	pop eax
	out 0x60, al

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0xF3
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	call PS2ControllerWaitDataWrite
	mov al, 0xC8
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0xF3
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0x64
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0xF3
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0x50
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin wheel mode init by setting sample rate to 200
	call PS2ControllerWaitDataWrite
	mov al, 0xF2
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60
	call PS2ControllerWaitDataRead
	in al, 0x60

	mov byte [tSystem.mouseID], al

	; see if this is one of those newfangled wheel mice
	; if it is, we skip the next section where we reapply default settings
	cmp al, 0x03
	je .skipDefaultSettings

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; use default settings
	call PS2ControllerWaitDataWrite
	mov al, 0xF6
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	.skipDefaultSettings:
	; here we set the packet size
	mov byte al, [tSystem.mouseID]
	cmp al, 0x03
	je .fancyMouse
	mov byte [tSystem.mousePacketByteSize], 0x03
	jmp .donePacketSetting
	.fancyMouse:
	mov byte [tSystem.mousePacketByteSize], 0x04
	.donePacketSetting:

	; select PS/2 device 2 to send next data byte to mouse
	call PS2ControllerWaitDataWrite
	mov al, 0xD4
	out 0x64, al
	; begin packet transmission
	call PS2ControllerWaitDataWrite
	mov al, 0xF4
	out 0x60, al
	call PS2ControllerWaitDataRead
	in al, 0x60

	; enable keyboard
	call PS2ControllerWaitDataWrite
	mov al, 0xAE
	out 0x64, al

	; limit mouse horizontally (I guess 640 pixels by defualt should work?)
	mov ax, 640
	shr ax, 1
	mov word [tSystem.mouseX], ax

	; limit mouse vertically (480 pixels sounds good I suppose)
	mov ax, 480
	shr ax, 1
	mov word [tSystem.mouseY], ax

	; init mouse wheel index
	mov word [tSystem.mouseZ], 0x7777

	mov esp, ebp
	pop ebp
ret



PS2ControllerWaitDataRead:
	; Reads data from the PS/2 controller
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov dword [tSystem.lastError], 0x00000000

	; set timeout value for roughly a couple seconds
	mov ebx, [tSystem.delayValue]
	shr ebx, 8
	mov ecx, 0x00000000

	.waitLoop:
		; wait until the controller is ready
		in al, 0x64
		and al, 00000001b
		cmp al, 0x01
		je .done
		; if we get here, the controller isn't ready, so see if we've timed out
		inc ecx
		cmp ebx, ecx
	jne .waitLoop
	; if we get here, we've timed out
	mov dword [tSystem.lastError], 0x0000FF00
	.done:

	mov esp, ebp
	pop ebp
ret



PS2ControllerWaitDataWrite:
	; Waits with timeout until the PS/2 controller is ready to accept data, then returns
	; Note: Uses the system delay value for timeout since interrupts may be disabled upon calling
	;
	;  input:
	;   n/a
	;
	;  output:
	;   n/a

	push ebp
	mov ebp, esp

	mov dword [tSystem.lastError], 0x00000000

	; set timeout value for roughly a couple seconds
	mov ebx, [tSystem.delayValue]
	shr ebx, 8
	mov ecx, 0x00000000

	.waitLoop:
		; wait until the controller is ready
		in al, 0x64
		and al, 00000010b
		cmp al, 0x00
		je .done
		; if we get here, the controller isn't ready, so see if we've timed out
		inc ecx
		cmp ebx, ecx
	jne .waitLoop
	; if we get here, we've timed out
	mov ax, 0xFF01
	jmp .done
	.done:

	mov esp, ebp
	pop ebp
ret
