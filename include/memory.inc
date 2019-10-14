; Night Kernel
; Copyright 2015 - 2019 by mercury0x0d
; memory.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; variable definitions
%include "include/memory defines.inc"





; function definitions
extern A20Check
extern A20Enable
extern A20EnableBIOS
extern A20EnableFastA20
extern A20EnableKeyboardController
extern A20EnablePortEE
extern MemProbe
extern MemAddressAlign
extern MemAddressToBlock
extern MemAllocate
extern MemAllocateAligned
extern MemCompare
extern MemCopy
extern MemDispose
extern MemFill
extern MemFindMostSuitable
extern MemInit
extern MemMergeBlocks
extern MemSearchWord
extern MemSearchDWord
extern MemSearchString
extern MemShrinkFromBeginning
extern MemShrinkFromEnd
extern MemSwapWordBytes
extern MemSwapDwordWords
extern Mem_Internal_MemListGrow
extern Mem_Internal_MemListShrink
extern PageDirInit
extern PageDirBuildTo
