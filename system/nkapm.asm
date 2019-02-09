; Night Kernel
; Copyright 1995 - 2019 by mercury0x000d
; nkapm.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.

apmversion          dw  -1      ; version storage

connectAPM:
                    mov ax,[cs:apmversion]
                    cmp ax, -1
                    jnz connectedAPM

                    push bx
                    push cx

                    mov ax, 0x5300
                    xor bx, bx          ; device ID of System BIOS (0000h)
                    int 0x15

                    pop cx
                    jc noAPM1
                    cmp bx, 0x504d      ; PM
                    jz gotAPM
NoAPM1:             xor ax, ax          ; NO APM
                    jmp noAPM2
gotAPM:             cmp ah, 1           ; Require v1
                    jb noAPM1
                    jz v1APM
v12APM:             mov ax, 0x102       ; APM 2.x or newer as APM 1.2
v1APM:              cmp al,2 
                    ja v12APM
                    push ax             ; Version
                    mov ax, 0x5301