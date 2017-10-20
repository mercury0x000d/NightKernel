; Night Kernel
; Copyright 2015 - 2016 by mercury0x000d
; hardware.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as published
; by the Free Software Foundation, either version 3 of the License, or (at
; your option) any later version.

; The Night Kernel is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
; for more details.

; You should have received a copy of the GNU General Public License along
; with the Night Kernel. If not, see <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the
; GPL License by which this program is covered.



bits 16



PrintFail:
 ; Prints an ASCIIZ failure message directly to the screen.
 ; Note: Uses text mode (assumed already set) not VESA.
 ; Note: For use in Real Mode only.
 ;  input:
 ;   address of string to print
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: ax, bl, es, di, ds, si

 ; set the proper mode
 mov ah, 0x00
 mov al, 0x03
 sti
 int 0x10
 cli

 pop ax
 pop si
 push ax

 ; write the string
 mov bl, 0x04
 mov ax, 0xB800
 mov ds, ax
 mov di, 0x0000
 mov ax, 0x0000
 mov es, ax

 .loopBegin:
 mov al, [es:si]

 ; have we reached the string end? if yes, exit the loop
 cmp al, 0x00
 je .end

 mov byte[ds:di], al
 inc di
 mov byte[ds:di], bl
 inc di
 inc si
 jmp .loopBegin
 .end:

ret



bits 32



KeyboardInit:
 ; Initializes the PS/2 keyboard
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, bx, ecx, edx

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
 pushad
 call PS2ControllerWaitDataRead
 popad
 in al, 0x60
 cmp al, 0xAA
 je .resetDone
 inc bh
 cmp bl, bh
 jne .loop
 .resetDone:

 ; now we set the custom stuff
 mov ebx, [tSystemInfo.delayValue]
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
 mov edx, tSystemInfo.keyboardType
 inc edx
 mov [edx] ,al
 call PS2ControllerWaitDataRead
 in al, 0x60
 dec edx
 mov [edx] ,al

 ; enable num lock
 call KeyboardNumLockSet

ret



KeyboardNumLockSet:
 ; Handles the internals of turning on Num Lock - sets the flag and turns on the LED
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al

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
ret



KeyGet:
 ; Returns the oldest key in the key buffer, or null if it's empty
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   key pressed in lowest byte of 32-bit value
 ;
 ;  changes: eax, ecx, edx, esi

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
 mov eax, 0x00000000
 mov byte al, [esi]

 ; update the read position
 inc cl
 mov byte [kKeyBufferRead], cl

 .done:
 ; push the data we got onto the stack and exit
 pop edx
 push eax
 push edx
ret



MouseInit:
 ; Initializes the PS/2 mouse
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: ax, bx

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

 mov byte [tSystemInfo.mouseID], al

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
 mov byte al, [tSystemInfo.mouseID]
 cmp al, 0x03
 je .fancyMouse
 mov byte [tSystemInfo.mousePacketByteSize], 0x03
 jmp .donePacketSetting
 .fancyMouse:
 mov byte [tSystemInfo.mousePacketByteSize], 0x04
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

 mov ax, [tSystemInfo.VESAWidth]
 shr ax, 1
 mov word [tSystemInfo.mouseX], ax

 mov ax, [tSystemInfo.VESAHeight]
 shr ax, 1
 mov word [tSystemInfo.mouseY], ax

 mov word [tSystemInfo.mouseZ], 0x7777

ret



PICDisableIRQs:
 ; Disables all IRQ lines across both PICs
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx

 mov al, 0xFF                     ; disable IRQs
 mov dx, [kPIC1DataPort]          ; set up PIC 1
 out dx, al
 mov dx, [kPIC2DataPort]          ; set up PIC 2
 out dx, al
ret



PICInit:
 ; Init & remap both PICs to use int numbers 0x20 - 0x2f
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx

 mov al, 0x11                     ; set ICW1
 mov dx, [kPIC1CmdPort]           ; set up PIC 1
 out dx, al
 mov dx, [kPIC2CmdPort]           ; set up PIC 2
 out dx, al

 mov al, 0x20                     ; set base interrupt to 0x20 (ICW2)
 mov dx, [kPIC1DataPort]
 out dx, al

 mov al, 0x28                     ; set base interrupt to 0x28 (ICW2)
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0x04                     ; set ICW3 to cascade PICs together
 mov dx, [kPIC1DataPort]
 out dx, al
 mov al, 0x02                     ; set ICW3 to cascade PICs together
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0x05                     ; set PIC 1 to x86 mode with ICW4
 mov dx, [kPIC1DataPort]
 out dx, al

 mov al, 0x01                     ; set PIC 2 to x86 mode with ICW4
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0                        ; zero the data register
 mov dx, [kPIC1DataPort]
 out dx, al
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0xFD
 mov dx, [kPIC1DataPort]
 out dx, al
 mov al, 0xFF
 mov dx, [kPIC2DataPort]
 out dx, al
ret



PICIntComplete:
 ; Tells both PICs the interrupt has been handled
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx

 mov al, 0x20                     ; sets the interrupt complete bit
 mov dx, [kPIC1CmdPort]           ; write bit to PIC 1
 out dx, al

 mov dx, [kPIC2CmdPort]           ; write bit to PIC 2
 out dx, al
ret



PICMaskAll:
 ; Masks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx


 mov dx, [kPIC1DataPort]
 in al, dx
 and al, 0xff
 out dx, al

 mov dx, [kPIC2DataPort]
 in al, dx
 and al, 0xff
 out dx, al
ret



PICMaskSet:
 ; Masks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx


 mov dx, [kPIC1DataPort]
 in al, dx
 and al, 0xff
 out dx, al

 mov dx, [kPIC2DataPort]
 in al, dx
 and al, 0xff
 out dx, al
ret



PICUnmaskAll:
 ; Unmasks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov al, 0x00
 mov dx, [kPIC1DataPort]
 out dx, al

 mov dx, [kPIC2DataPort]
 out dx, al
ret



PITInit:
 ; Init the PIT for our timing purposes
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov ax, 1193180 / 256

 mov al, 00110110b
 out 0x43, al

 out 0x40, al
 xchg ah, al
 out 0x40, al
ret



PS2ControllerWaitDataRead:
 ; Reads data from the PS/2 controller
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, ebx, ecx

 mov dword [tSystemInfo.lastError], 0x00000000

 ; set timeout value for roughly a couple seconds
 mov ebx, [tSystemInfo.delayValue]
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
 mov dword [tSystemInfo.lastError], 0x0000FF00
 .done:
ret



PS2ControllerWaitDataWrite:
 ; Waits with timeout until the PS/2 controller is ready to accept data, then returns
 ; Note: Uses the system delay value for timeout since interrupts may be disabled upon calling
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: ax, ebx, ecx

  mov dword [tSystemInfo.lastError], 0x00000000

 ; set timeout value for roughly a couple seconds
 mov ebx, [tSystemInfo.delayValue]
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
ret



Reboot:
 ; Performs a warm reboot of the PC
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: al, dx

 mov dx, 0x92
 in al, dx
 or al, 00000001b
 out dx, al

 ; and now, for the return we'll never reach...
ret



SpeedDetect:
 ; Determines how many iterations of a random activity the CPU is capable of in one second
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   number of iterations
 ;
 ;  changes: ebx, ecx, edx

 mov ebx, 0x00000000
 mov ecx, 0x00000000
 mov edx, 0x00000000
 mov al, [tSystemInfo.tickCounter]
 mov ah, al
 dec ah
 .loop1:
 inc ebx
 push ebx
 inc ecx
 push ecx
 inc edx
 push edx
 pop edx
 pop ecx
 pop ebx
 mov al, [tSystemInfo.tickCounter]
 cmp al, ah
 jne .loop1
 pop ebx
 push ecx
 push ebx
ret



VESAPlot24:
 ; Draws a pixel directly to the VESA linear framebuffer
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: eax, ebx, ecx, esi

 pop esi                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get color attribute
 push esi                         ; push return address back on the stack

 ; calculate write position
 mov dx, [tVESAModeInfo.XResolution]
 mul edx
 add ax, bx
 mov edx, 3
 mul edx
 add eax, [tVESAModeInfo.PhysBasePtr]

 ; do the write
 mov byte [eax], cl
 inc eax
 ror ecx, 8
 mov byte [eax], cl
 inc eax
 ror ecx, 8
 mov byte [eax], cl
 ror ecx, 16
ret



VESAPlot32:
 ; Draws a pixel directly to the VESA linear framebuffer
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: eax, ebx, ecx, esi

 pop esi                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get color attribute
 push esi                         ; push return address back on the stack

 ; calculate write position
 mov dx, [tVESAModeInfo.XResolution]
 mul edx
 add ax, bx
 mov edx, 4
 mul edx
 add eax, [tVESAModeInfo.PhysBasePtr]

 ; do the write
 mov dword [eax], ecx
ret



VESAPrint24:
 ; Prints an ASCIIZ string directly to the VESA framebuffer in 24 bit color modes
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;   address of string to print
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: eax, ebx, ecx, edx, ebp, edi, esi

 pop edx                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get text color
 pop ebp                          ; get background color
 pop esi                          ; get string address
 push edx                         ; push return address back on the stack

 ; calculate write position into edi and save to the stack
 mov edx, 0
 mov dx, [tVESAModeInfo.XResolution] ; can probably be optimized to use bytes per scanline field to eliminate doing multiply
 mul edx
 add ax, bx
 mov edx, 3
 mul edx
 add eax, [tVESAModeInfo.PhysBasePtr]
 mov edi, eax
 push edi

 ; keep the number of bytes in a scanline handy in edx for later
 mov edx, 0
 mov dx, [tVESAModeInfo.BytesPerScanline]

 ; time to step through the string and draw it
 .StringDrawLoop:
 ; put the first character of the string into bl
 mov byte bl, [esi]

 ; see if the char we just got is null - if so, we exit
 cmp bl, 0x00
 jz .End

 ; it wasn't, so we need to calculate the beginning of the data for this char in the font table into eax
 mov eax, 0
 mov al, bl
 mov bh, 16
 mul bh
 add eax, kKernelFont

 .FontBytesLoop:
 ; save the contents of edx and move font byte 1 into dl, making a backup copy in dh
 push edx
 mov byte dl, [eax]
 mov byte dh, dl

 ; plot accordingly
 and dl, 10000000b
 cmp dl, 0
 jz .PointSkipA
 .PointPlotA:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneA
 .PointSkipA:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneA:
 mov byte dl, dh

 ; plot accordingly
 and dl, 01000000b
 cmp dl, 0
 jz .PointSkipB
 .PointPlotB:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneB
 .PointSkipB:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneB:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00100000b
 cmp dl, 0
 jz .PointSkipC
 .PointPlotC:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneC
 .PointSkipC:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneC:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00010000b
 cmp dl, 0
 jz .PointSkipD
 .PointPlotD:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneD
 .PointSkipD:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneD:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00001000b
 cmp dl, 0
 jz .PointSkipE
 .PointPlotE:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneE
 .PointSkipE:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneE:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000100b
 cmp dl, 0
 jz .PointSkipF
 .PointPlotF:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneF
 .PointSkipF:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneF:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000010b
 cmp dl, 0
 jz .PointSkipG
 .PointPlotG:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneG
 .PointSkipG:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneG:
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000001b
 cmp dl, 0
 jz .PointSkipH
 .PointPlotH:
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 jmp .PointDoneH
 .PointSkipH:
 push ecx
 mov ecx, ebp
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 8
 mov byte [edi], cl
 inc edi
 ror ecx, 16
 pop ecx
 .PointDoneH:
 mov byte dl, dh

 ; increment the font pointer
 inc eax

 ; set the framebuffer pointer to the next line
 sub edi, 24
 pop edx
 add edi, edx

 dec bh
 cmp bh, 0
 jne .FontBytesLoop


 ; increment the string pointer
 inc esi

 ;restore the framebuffer pointer to its original value, save a copy adjusted for the next loop
 pop edi
 add edi, 24
 push edi

 jmp .StringDrawLoop

 .End:

 ;get rid of that extra saved value
 pop edi

ret



VESAPrint32:
 ; Prints an ASCIIZ string directly to the VESA framebuffer in 32 bit color modes
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color
 ;   background color
 ;   address of string to print
 ;
 ;  output:
 ;   n/a
 ;
 ;  changes: eax, ebx, ecx, edx, ebp, edi, esi

 pop edx                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get text color
 pop ebp                          ; get background color
 pop esi                          ; get string address
 push edx                         ; push return address back on the stack

 ; calculate write position into edi and save to the stack
 mov edx, 0
 mov dx, [tVESAModeInfo.XResolution] ; can probably be optimized to use bytes per scanline field to eliminate doing multiply
 mul edx
 add ax, bx
 mov edx, 4
 mul edx
 add eax, [tVESAModeInfo.PhysBasePtr]
 mov edi, eax
 push edi

 ; keep the number of bytes in a scanline handy in edx for later
 mov edx, 0
 mov dx, [tVESAModeInfo.BytesPerScanline]

 ; time to step through the string and draw it
 .StringDrawLoop:
 ; put the first character of the string into bl
 mov byte bl, [esi]

 ; see if the char we just got is null - if so, we exit
 cmp bl, 0x00
 jz .End

 ; it wasn't, so we need to calculate the beginning of the data for this char in the font table into eax
 mov eax, 0
 mov al, bl
 mov bh, 16
 mul bh
 add eax, kKernelFont

 .FontBytesLoop:
 ; save the contents of edx and move font byte 1 into dl, making a backup copy in dh
 push edx
 mov byte dl, [eax]
 mov byte dh, dl

 ; plot accordingly
 push eax

 test dl, 10000000b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi], eax

 test dl, 1000000b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+4], eax

 test dl, 100000b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+8], eax

 test dl, 10000b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+12], eax

 test dl, 1000b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+16], eax

 test dl, 100b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+20], eax

 test dl, 10b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+24], eax

 test dl, 1b
 cmovnz eax, ecx
 cmovz  eax, ebp
 mov [edi+28], eax

 add edi,32

 pop eax

 ; increment the font pointer
 inc eax

 ; set the framebuffer pointer to the next line
 sub edi, 32
 pop edx
 add edi, edx

 dec bh
 cmp bh, 0
 jne .FontBytesLoop


 ; increment the string pointer
 inc esi

 ;restore the framebuffer pointer to its original value, save a copy adjusted for the next loop
 pop edi
 add edi, 32
 push edi

 jmp .StringDrawLoop

 .End:

 ;get rid of that extra saved value
 pop edi
ret


