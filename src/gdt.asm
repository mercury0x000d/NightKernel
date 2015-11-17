; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; gdt.asm is a part of the Night DOS Kernel

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



;----------------------------------------------------------
; GDT support routines
;----------------------------------------------------------

%ifndef __GDT_INC
%define __GDT_INC

bits  16

;----------------------------------------------------------
; load_GDT()
;     - Install our GDT
;----------------------------------------------------------

load_GDT:

pusha                   ; save registers
lgdt  [GDTHeader]          ; load GDT into GDTR
popa                    ; restore registers
ret                        ; Return

;----------------------------------------------------------
; Global Descriptor Table (GDT)
;
;  --- Complete with Kernel and User space
;----------------------------------------------------------

gdt_start:

;----------------------------------------------------------
; Null descriptor (Offset 0x0)
;----------------------------------------------------------
dd 0
dd 0

;----------------------------------------------------------
; Kernel space code (Offset 0x8)
;----------------------------------------------------------
dw 0xffff                  ; limit low
dw 0x0000                  ; base low
db 0x00                    ; base middle
db 10011010b               ; access
db 11001111b               ; granularity
db 0x00                    ; base high

;----------------------------------------------------------
; Kernel space data (Offset 0x10)    
;----------------------------------------------------------
dw 0xffff                  ; limit low
dw 0x0000                  ; base low
db 0x00                    ; base middle
db 10010010b               ; access
db 11001111b               ; granularity
db 0x00                    ; base high

;----------------------------------------------------------
; User Space code (Offset 0x18)
;----------------------------------------------------------
dw 0xffff                  ; limit low
dw 0x0000                  ; base low
db 0x00                    ; base middle
db 11111010b               ; access
db 11001111b               ; granularity
db 0x00                    ; base high

;----------------------------------------------------------
; User Space data (Offset 0x20)
;----------------------------------------------------------
dw 0xffff                  ; limit low
dw 0x0000                  ; base low
db 0x00                    ; base middle
db 11110010b               ; access
db 11001111b               ; granularity
db 0x00                    ; base high

gdt_end:

GDTHeader:
dw gdt_end - gdt_start - 1    ; size of GDT
dd gdt_start               ; base of GDT

%endif ;__GDT_INC
