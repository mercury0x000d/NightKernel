; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; idt.asm is a part of the Night DOS Kernel

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



IDTWrite:
 ; Formats the passed data and writes it to the IDT in the slot specified
 ;  input:
 ;   IDT index 
 ;   ISR selector
 ;   ISR base address
 ;   flags
 ;
 ;  output:
 ;   n/a

 pop esi                          ; save ret address
 pop ebx                          ; get destination IDT index
 mov eax, 8                       ; calc the destination offset into the IDT
 mul ebx
 mov edi, [kIDTPtr]               ; get IDT's base address
 add edi, eax                     ; calc the actual write address

 pop ebx                          ; get ISR selector
 
 pop ecx                          ; get ISR base address
 
 mov eax, 0x0000ffff
 and eax, ecx                     ; get low word of base address in eax
 mov word [edi], ax               ; write low word
 add edi, 2                       ; adjust the destination pointer
 
 mov word [edi], bx               ; write selector
 add edi, 2                       ; adjust the destination pointer again

 mov al, 0x00
 mov byte [edi], al               ; write null (reserved byte)
 inc edi                          ; adjust the destination pointer again
 
 pop edx                          ; get the flags
 mov byte [edi], dl               ; and write those flags!
 inc edi                          ; guess what we're doing here :D
 
 shr ecx, 16                      ; shift base address right 16 bits to
                                  ; get high word in position
 mov eax, 0x0000ffff
 and eax, ecx                     ; get high word of base address in eax
 mov word [edi], ax               ; write high word

 push esi                         ; restore ret address
ret