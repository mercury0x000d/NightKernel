; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; kernel.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; variable definitions
%include "include/kernelDefines.inc"

extern tss.back_link
extern tss.esp0
extern tss.ss0
extern tss.esp1
extern tss.ss1
extern tss.esp2
extern tss.ss2
extern tss.cr3
extern tss.eip
extern tss.eflags
extern tss.eax
extern tss.ecx
extern tss.edx
extern tss.ebx
extern tss.esp
extern tss.ebp
extern tss.esi
extern tss.edi
extern tss.es
extern tss.cs
extern tss.ss
extern tss.ds
extern tss.fs
extern tss.gs
extern tss.ldt
extern tss.trap
extern tss.iomap_base
extern tss.end
