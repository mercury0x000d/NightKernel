; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; lists.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; variable definitions
%include "include/listsDefines.inc"





; function definitions
extern LMBitfieldInit
extern LMBitfieldScanClear
extern LMBitfieldScanSet
extern LMBitfieldSpaceCalc
extern LMBitfieldValidate
extern LMBitfieldValidateElement
extern LMBitClear
extern LMBitClearRange
extern LMBitFlip
extern LMBitFlipRange
extern LMBitGet
extern LMBitSet
extern LMBitSetRange
extern LMCountBitsSet
extern LMElementAddressGet
extern LMElementCountGet
extern LMElementCountSet
extern LMElementDelete
extern LMElementDuplicate
extern LMElementSizeGet
extern LMElementValidate
extern LMItemAddAtSlot
extern LMListCompact
extern LMListInit
extern LMListSearch
extern LMListSpaceCalc
extern LMListValidate
extern LMSlotFindFirstFree
extern LMSlotFreeTest
