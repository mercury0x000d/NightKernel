; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; inthandl.asm is a part of the Night DOS Kernel

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



IntUnsupported:
cli
pusha
push 0x07
push 1
push 1
push kUnsupportedInt
call PrintString
call PICIntComplete
popa
sti
iret

ISR00:
cli
call PICIntComplete
sti
iret

ISR01:
cli
call PICIntComplete
sti
iret

ISR02:
cli
call PICIntComplete
sti
iret

ISR03:
cli
call PICIntComplete
sti
iret

ISR04:
cli
call PICIntComplete
sti
iret

ISR05:
cli
call PICIntComplete
sti
iret

ISR06:
cli
call PICIntComplete
sti
iret

ISR07:
cli
call PICIntComplete
sti
iret

ISR08:
cli
call PICIntComplete
sti
iret

ISR09:
cli
call PICIntComplete
sti
iret

ISR0A:
cli
call PICIntComplete
sti
iret

ISR0B:
cli
call PICIntComplete
sti
iret

ISR0C:
cli
call PICIntComplete
sti
iret

ISR0D:
cli
call PICIntComplete
sti
iret

ISR0E:
cli
call PICIntComplete
sti
iret

ISR0F:
cli
call PICIntComplete
sti
iret

ISR10:
cli
call PICIntComplete
sti
iret

ISR11:
cli
call PICIntComplete
sti
iret

ISR12:
cli
call PICIntComplete
sti
iret

ISR13:
cli
call PICIntComplete
sti
iret

ISR14:
cli
call PICIntComplete
sti
iret

ISR15:
cli
call PICIntComplete
sti
iret

ISR16:
cli
call PICIntComplete
sti
iret

ISR17:
cli
call PICIntComplete
sti
iret

ISR18:
cli
call PICIntComplete
sti
iret

ISR19:
cli
call PICIntComplete
sti
iret

ISR1A:
cli
call PICIntComplete
sti
iret

ISR1B:
cli
call PICIntComplete
sti
iret

ISR1C:
cli
call PICIntComplete
sti
iret

ISR1D:
cli
call PICIntComplete
sti
iret

ISR1E:
cli
call PICIntComplete
sti
iret

ISR1F:
cli
call PICIntComplete
sti
iret

ISR20:                           ; timer tick interrupt
cli
inc dword [0x00000500]
cmp byte [0x00000500], 128
jz .incrementTicks
.resume:
call PICIntComplete
sti
iret
.incrementTicks:
mov byte [0x00000500], 0
inc dword [0x00000501]
jmp .resume

ISR21:
cli
call PICIntComplete
in al, 0x60
sti
iret

ISR22:
cli
call PICIntComplete
sti
iret

ISR23:
cli
call PICIntComplete
sti
iret

ISR24:
cli
call PICIntComplete
sti
iret

ISR25:
cli
call PICIntComplete
sti
iret

ISR26:
cli
call PICIntComplete
sti
iret

ISR27:
cli
call PICIntComplete
sti
iret

ISR28:
cli
call PICIntComplete
sti
iret

ISR29:
cli
call PICIntComplete
sti
iret

ISR2A:
cli
call PICIntComplete
sti
iret

ISR2B:
cli
call PICIntComplete
sti
iret

ISR2C:
cli
call PICIntComplete
sti
iret

ISR2D:
cli
call PICIntComplete
sti
iret

ISR2E:
cli
call PICIntComplete
sti
iret

ISR2F:
cli
call PICIntComplete
sti
iret



