; Night DOS Kernel (kernel.asm) version 0.03
; Copyright 1995-2015 by mercury0x000d

; globals.asm is a part of the Night DOS Kernel

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



; vars 'n' such
kCopyright1          db     'Night DOS Kernel     A 32-bit protected mode replacement for the FreeDOS kernel', 0x00
kCopyright2          db     'version 0.03         2015 by Mercury0x000d, Antony Gordon, Maarten Vermeulen', 0x00
kCRLF                db     0x0d, 0x0a, 0x00
kNull                db     0
kGDTDS               dd     0x00000500
kGDTPtr              dd     0x00008000
kIDTPtr              dd     0x00018000
kVideoMem            dd     0x000b8000
kPIC1CmdPort         dw     0x0020
kPIC1DataPort        dw     0x0021
kPIC2CmdPort         dw     0x00a0
kPIC2DataPort        dw     0x00a1
kPITPort             dw     0x0040
kHexDigits           db     '0123456789ABCDEF'
kUnsupportedInt      db     'An unsupported interrupt has been called'
