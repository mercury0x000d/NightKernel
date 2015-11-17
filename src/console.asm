; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; console.asm is a part of the Night DOS Kernel

; The Night DOS Kernel is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as published
; by the Free Software Foundation, either version 3 of the License, or (at
; your option) any later version.

; The Night DOS Kernel is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
; for more details.

; You should have received a copy of the GNU General Public License along
; with the Night DOS Kernel. If not, see <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the
; GPL License by which this program is covered.



PrintHex:
 ; Prints a hex value to the screen. Assumes text mode already set.
 ;  input:
 ;   value to print
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;
 ;  output:
 ;   n/a

 pop eax                          ; get return address for end ret
 pop esi                          ; get hex value
 pop ecx                          ; get horizontal position
 pop edx                          ; get vertical position
 pop ebx                          ; get color attribute
 push eax                         ; push return address back on the stack

 mov edi, [kVideoMem]             ; load edi with video memory address

 dec edx                          ; calculate text position offset
 mov eax, 160
 mul edx
 add edi, eax                     ; alter edi for vertical text position

 dec ecx
 mov eax, 2
 mul ecx
 add edi, eax                     ; alter edi for horizontal text position

 mov ecx, 0xF0000000
 and ecx, esi
 shr ecx, 28
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x0F000000
 and ecx, esi
 shr ecx, 24
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x00F00000
 and ecx, esi
 shr ecx, 20
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x000F0000
 and ecx, esi
 shr ecx, 16
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x0000F000
 and ecx, esi
 shr ecx, 12
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x00000F00
 and ecx, esi
 shr ecx, 8
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x000000F0
 and ecx, esi
 shr ecx, 4
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

 mov ecx, 0x0000000F
 and ecx, esi
 add ecx, kHexDigits
 mov al, [ecx]
 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi

ret



PrintString:
 ; Prints an ASCIIZ string to the screen. Assumes text mode already set.
 ;  input:
 ;   address of string to print
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;
 ;  output:
 ;   n/a

 pop eax                          ; get return address for end ret
 pop esi                          ; get string address
 pop ecx                          ; get horizontal position
 pop edx                          ; get vertical position
 pop ebx                          ; get color attribute
 push eax                         ; push return address back on the stack

 mov edi, [kVideoMem]             ; load edi with video memory address

 dec edx                          ; calculate text position offset
 mov eax, 160
 mul edx
 add edi, eax                     ; alter edi for vertical text position

 dec ecx
 mov eax, 2
 mul ecx
 add edi, eax                     ; alter edi for horizontal text position

 .loopBegin:
 mov al, [esi]
 inc esi

 cmp al, [kNull]                  ; have we reached the string end?
 jz .end                          ; if yes, jump to the end

 mov byte[edi], al
 inc edi
 mov byte[edi], bl
 inc edi
 jmp .loopBegin
 .end:
ret



