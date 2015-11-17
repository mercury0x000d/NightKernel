; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; setints.asm is a part of the Night DOS Kernel

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



push 0x8e
push ISR00
push 0x08
push 0x00
call IDTWrite

push 0x8e
push ISR01
push 0x08
push 0x01
call IDTWrite

push 0x8e
push ISR02
push 0x08
push 0x02
call IDTWrite

push 0x8e
push ISR03
push 0x08
push 0x03
call IDTWrite

push 0x8e
push ISR04
push 0x08
push 0x04
call IDTWrite

push 0x8e
push ISR05
push 0x08
push 0x05
call IDTWrite

push 0x8e
push ISR06
push 0x08
push 0x06
call IDTWrite

push 0x8e
push ISR07
push 0x08
push 0x07
call IDTWrite

push 0x8e
push ISR08
push 0x08
push 0x08
call IDTWrite

push 0x8e
push ISR09
push 0x08
push 0x09
call IDTWrite

push 0x8e
push ISR0A
push 0x08
push 0x0A
call IDTWrite

push 0x8e
push ISR0B
push 0x08
push 0x0B
call IDTWrite

push 0x8e
push ISR0C
push 0x08
push 0x0C
call IDTWrite

push 0x8e
push ISR0D
push 0x08
push 0x0D
call IDTWrite

push 0x8e
push ISR0E
push 0x08
push 0x0E
call IDTWrite

push 0x8e
push ISR0F
push 0x08
push 0x0F
call IDTWrite

push 0x8e
push ISR10
push 0x08
push 0x10
call IDTWrite

push 0x8e
push ISR11
push 0x08
push 0x11
call IDTWrite

push 0x8e
push ISR12
push 0x08
push 0x12
call IDTWrite

push 0x8e
push ISR13
push 0x08
push 0x13
call IDTWrite

push 0x8e
push ISR14
push 0x08
push 0x14
call IDTWrite

push 0x8e
push ISR15
push 0x08
push 0x15
call IDTWrite

push 0x8e
push ISR16
push 0x08
push 0x16
call IDTWrite

push 0x8e
push ISR17
push 0x08
push 0x17
call IDTWrite

push 0x8e
push ISR18
push 0x08
push 0x18
call IDTWrite

push 0x8e
push ISR19
push 0x08
push 0x19
call IDTWrite

push 0x8e
push ISR1A
push 0x08
push 0x1A
call IDTWrite

push 0x8e
push ISR1B
push 0x08
push 0x1B
call IDTWrite

push 0x8e
push ISR1C
push 0x08
push 0x1C
call IDTWrite

push 0x8e
push ISR1D
push 0x08
push 0x1D
call IDTWrite

push 0x8e
push ISR1E
push 0x08
push 0x1E
call IDTWrite

push 0x8e
push ISR1F
push 0x08
push 0x1F
call IDTWrite

push 0x8e
push ISR20
push 0x08
push 0x20
call IDTWrite

push 0x8e
push ISR21
push 0x08
push 0x21
call IDTWrite

push 0x8e
push ISR22
push 0x08
push 0x22
call IDTWrite

push 0x8e
push ISR23
push 0x08
push 0x23
call IDTWrite

push 0x8e
push ISR24
push 0x08
push 0x24
call IDTWrite

push 0x8e
push ISR25
push 0x08
push 0x25
call IDTWrite

push 0x8e
push ISR26
push 0x08
push 0x26
call IDTWrite

push 0x8e
push ISR27
push 0x08
push 0x27
call IDTWrite

push 0x8e
push ISR28
push 0x08
push 0x28
call IDTWrite

push 0x8e
push ISR29
push 0x08
push 0x29
call IDTWrite

push 0x8e
push ISR2A
push 0x08
push 0x2A
call IDTWrite

push 0x8e
push ISR2B
push 0x08
push 0x2B
call IDTWrite

push 0x8e
push ISR2C
push 0x08
push 0x2C
call IDTWrite

push 0x8e
push ISR2D
push 0x08
push 0x2D
call IDTWrite

push 0x8e
push ISR2E
push 0x08
push 0x2E
call IDTWrite

push 0x8e
push ISR2F
push 0x08
push 0x2F
call IDTWrite



